# MMA Reference Guide

This document provides architectural context for investigating MMA (Multi-Metric
Allocator) behavior on CockroachDB clusters. It explains concepts and points to
source code for exact definitions. Since MMA is under active development, always
verify details against the source when precision matters.

All source paths are relative to the CockroachDB repository root.

## CockroachDB Rebalancing System Overview

MMA is one of several components that affect replica and lease placement.
Understanding MMA behavior requires understanding how it fits alongside the
others. Several of these components run simultaneously and independently, which
means rebalancing activity you observe may not be caused by MMA.

### Component Summary

| Component | Dimensions | Runs When | Key Behavior |
|-----------|-----------|-----------|--------------|
| **Replica Scanner** | N/A (triggers queues) | Every ~10 min per store | Per-store, runs `MaybeAddAsync` on each registered queue for each replica. Active in both SMA and MMA modes. |
| **Replicate Queue** | Replica count, diversity, constraints, full disks | On-demand (scanner enqueues) | Handles under/over-replicated ranges, dead/decommissioning replicas, range count convergence (if count-based rebalancing enabled), diversity/constraint satisfaction, full disk shedding. Active in both modes. |
| **Lease Queue** | Lease validity, lease preferences, locality/workload following, IO overload | On-demand (scanner enqueues) | Handles invalid leases, lease count convergence, lease preferences from span configs. Rate-limited to 1 optional transfer per `kv.allocator.min_lease_transfer_interval` (1s). Active in both modes. |
| **Allocator** | N/A (decision library) | Called by queues and rebalancers | Stateless decision-making library. Does not initiate rebalancing. Called by the store rebalancer, replicate queue, and lease queue. |
| **Store Rebalancer (SMA)** | CPU *or* QPS (single metric) | Every ~1 min | Load-based, single metric configured via `kv.allocator.load_based_rebalancing.objective`. **Disabled when MMA is enabled.** Only acts when local store exceeds cluster mean by a threshold. Attempts lease transfers first, then replicas. |
| **MMA** | CPU, Write Bandwidth, ByteSize | Every ~1 min | Multi-metric. Replaces the Store Rebalancer. Computes `storeLoadSummary` per store, identifies overloaded stores, attempts lease transfers then replica moves. |

### What MMA Replaces vs What Still Runs

When MMA is enabled:
- The **Store Rebalancer** (SMA's load-based component) is **disabled**.
- The **Replicate Queue** and **Lease Queue** still run independently. They
  handle count-based convergence, constraint satisfaction, IO overload, lease
  preferences, etc. — concerns orthogonal to MMA's load-based rebalancing.
- The **Replica Scanner** still runs and enqueues to those queues.

This means observed replica/lease movement may come from MMA or from the queues.
Use MMA metrics (`mma.change.rebalance.*`) vs queue metrics to distinguish.

### Enabling MMA

MMA is controlled by the cluster setting `kv.allocator.load_based_rebalancing`:
- `off` — no load-based rebalancing
- `leases` — SMA: lease-only rebalancing
- `leases and replicas` — SMA: lease and replica rebalancing (default)
- `multi-metric only` — MMA enabled, replaces SMA store rebalancer
- `multi-metric and count` — MMA enabled, also does count-based convergence

See: `pkg/kv/kvserver/kvserverbase/base.go` for the setting definition.

## MMA Architecture

### Key Types and Data Flow

```
StoreLoadMsg (via gossip)         StoreLeaseholderMsg (from local store)
        |                                     |
        v                                     v
  ProcessStoreLoadMsg()              ComputeChanges()
        |                                     |
        v                                     v
  allocatorState.cs (clusterState)  ------>  rebalanceStores()
                                              |
                                              v
                                       []ExternalRangeChange
                                              |
                                              v
                                    mmaStoreRebalancer applies changes
                                              |
                                              v
                                    AdjustPendingChangeDisposition() (feedback)
```

- **`allocatorState`** — Top-level struct, holds a mutex and the `clusterState`.
  All `Allocator` interface methods acquire this mutex.
  See: `pkg/kv/kvserver/allocator/mmaprototype/allocator_state.go`

- **`clusterState`** — Holds per-store state (`storeState`), per-range state
  (`rangeState`), per-node state, and the `meansMemo` for caching load means.
  See: `pkg/kv/kvserver/allocator/mmaprototype/cluster_state.go`

- **`rebalanceEnv`** — Created fresh for each `rebalanceStores()` invocation.
  Holds the `clusterState`, limits (max range moves, max lease transfers),
  thresholds, and accumulated changes.
  See: `pkg/kv/kvserver/allocator/mmaprototype/cluster_state_rebalance_stores.go`

- **`mmaStoreRebalancer`** — Integration layer in `kvserver`. Runs a periodic
  loop, calls `ComputeChanges()`, and applies the returned changes.
  See: `pkg/kv/kvserver/mma_store_rebalancer.go`

- **`AllocatorSync`** — Coordinates between MMA and the replicate/lease queues
  to prevent conflicting concurrent decisions.
  See: `pkg/kv/kvserver/mmaintegration/allocator_sync.go`

### The Rebalancing Loop

`mmaStoreRebalancer.run()` ticks on a jittered interval (default ~1 minute,
controlled by `kv.allocator.load_based_rebalance.interval`). On each tick:

1. Calls `rebalance()` with `periodicCall=true`.
2. If changes were made, immediately calls `rebalance()` again with
   `periodicCall=false` (tight loop to drain pending work).
3. Stops when no changes are computed.

Each `rebalance()` call invokes `ComputeChanges()` on the allocator, which
calls `rebalanceStores()`.

## Load Dimensions

MMA tracks three primary load dimensions per store:

| Dimension | Unit | Source |
|-----------|------|--------|
| `CPURate` | nanoseconds/sec | Node-level CPU divided equally among stores on that node |
| `WriteBandwidth` | bytes/sec | Per-store disk write bandwidth |
| `ByteSize` | bytes | Logical bytes consumed by replicas (MVCC stats) |

See: `pkg/kv/kvserver/allocator/mmaprototype/load.go` for `LoadDimension`,
`LoadVector`, and related types.

### Utilization vs Equal-Load Balancing

- When **capacity is known** (CPU, disk), MMA balances on **utilization**
  (load/capacity). This handles heterogeneous clusters correctly — all stores
  should run at similar utilization regardless of size.
- When **capacity is unknown** (`WriteBandwidth` has `UnknownCapacity`), MMA
  balances towards **equal absolute load** across stores.
- Capacity-weighted mean: computed as `sum(load)/sum(capacity)`, not the
  average of individual utilizations.

### Secondary Dimensions (Not Yet Active)

`LeaseCount` and `ReplicaCount` are defined as `SecondaryLoadDimension` but are
not yet hooked up to the main rebalancing loop. The plan is for MMA to
eventually replace the replicate and lease queues' count-based convergence.

## Store Load Classification

Each store's load is classified per dimension and then aggregated into a
`storeLoadSummary`. This is the key data structure for understanding MMA's
decisions.

### Load Summary Levels

Defined in `load.go`, the `loadSummary` enum:

| Level | Meaning |
|-------|---------|
| `loadLow` | Load is >10% below cluster mean |
| `loadNormal` | Load is within ~5% of mean |
| `loadNoChange` | Load is 5-10% above mean; don't add or remove load |
| `overloadSlow` | Load is >10% above mean; shed load (non-urgent) |
| `overloadUrgent` | Utilization is very high; shed load urgently |

### How Classification Works

`loadSummaryForDimension()` in `load.go` computes the level for a single
dimension. It considers:

1. **Distance from mean** (`fractionAbove = load/meanLoad - 1.0`):
   - `> 0.10` => at least `overloadSlow`
   - `< -0.10` => `loadLow`
   - `0.05 to 0.10` => `loadNoChange`
   - `-0.10 to 0.05` => `loadNormal`

2. **Utilization relative to capacity** (when capacity is known):
   - `> 90%` utilization => `overloadUrgent`
   - `> 75%` and `> 1.5x` mean utilization => `overloadUrgent`
   - `> 75%` => at least `overloadSlow`
   - `> 1.75x` mean utilization => `overloadSlow`

3. **Dimension-specific caps**:
   - ByteSize: capped at `loadNormal` when utilization < 50% (avoid thrashing
     on a dimension that isn't actually constrained)
   - CPURate: capped at `loadNormal` when utilization < 5%

### storeLoadSummary

The `storeLoadSummary` struct (in `store_load_summary.go`) aggregates:
- `sls` — overall store load summary (worst across all dimensions)
- `nls` — node-level load summary (CPU only, since CPU is shared across stores)
- `worstDim` — which dimension drove the overall `sls`
- `dimSummary[dim]` — per-dimension breakdown
- `maxFractionPendingIncrease/Decrease` — pending change fraction

## The Rebalancing Algorithm

`rebalanceStores()` in `cluster_state_rebalance_stores.go` is the core.

### Phase 1: Identify Overloaded Stores

1. Compute cluster means for all stores.
2. For each store, compute `storeLoadSummary` relative to the cluster mean.
3. A store is a shedding candidate if:
   - `sls >= overloadSlow`
   - Pending decrease fraction < threshold (0.1)
   - No pending increase (within epsilon)

### Phase 2: Track Overload Duration

Each store tracks `overloadStartTime` and `overloadEndTime`. When a store
transitions to overloaded, the start time is recorded. When it drops below
`loadNoChange`, the end time is recorded. There is a grace period
(`overloadGracePeriod = 1 minute`) before the overload interval resets.

This duration determines how aggressively MMA picks targets (see ignore levels).

### Phase 3: Sort and Process Shedding Stores

Shedding stores are sorted by:
1. Local store first (local store can transfer leases directly)
2. Node-level overload (higher first)
3. Store-level overload (higher first)

For each shedding store, MMA attempts to shed load:

### Phase 4: Lease Transfers (Local Store Only)

If the local store is CPU-overloaded, attempt lease transfers first:
- Leases can only be transferred from the local store (it holds them).
- Find ranges where the local store is leaseholder and the shedding store has
  a replica.
- Evaluate candidates: stores that are in the same constraint set, have
  acceptable load levels, and won't become overloaded.
- If any leases were transferred, skip replica moves for this store (wait for
  the next tick to see the effect).

### Phase 5: Replica Moves

For each range in the store's top-K list (sorted by load on the worst
dimension):
1. Check range doesn't have pending changes or recent failures.
2. Analyze constraints to find valid replacement stores.
3. Build candidate set with pre-means and post-means filtering.
4. Pick a target considering load summary, diversity score, and lease
   preferences.
5. If successful, record the change. MMA emits at most 1 replica move per
   `rebalanceStores()` invocation (but may emit up to 8 lease transfers).

### Ignore Levels (Desperation)

As overload duration increases, MMA becomes more willing to accept suboptimal
targets:

| Level | When | Effect |
|-------|------|--------|
| `ignoreLoadNoChangeAndHigher` | Default (short duration) | Only consider stores with `loadNormal` or `loadLow` |
| `ignoreLoadThresholdAndHigher` | After ~5 min overloaded | Also consider stores at `loadNoChange` |
| `ignoreHigherThanLoadThreshold` | After ~8 min overloaded | Consider any store that wouldn't become worse than source |

### Remote Store Lease Shedding Grace Period

For remote stores that are CPU-overloaded, MMA waits
`remoteStoreLeaseSheddingGraceDuration` (2 minutes) before shedding replicas.
This gives the remote store's own leaseholder a chance to shed leases first
(which is cheaper than moving replicas).

## Candidate Filtering

### Pre-Means Filtering

Excludes stores before computing the mean for the candidate set:
- Stores with non-OK disposition (draining, dead, suspect, decommissioning,
  high disk utilization)
- Rationale: these stores can't accept work and shouldn't skew the mean

### Post-Means Filtering

Excludes candidates after computing the mean:
- Stores already hosting a replica of the range (can't place two replicas of
  the same range on the same node)
- The shedding store itself
- Stores whose load summary (relative to the candidate-set mean) is worse than
  the source store's, to prevent thrashing
- Stores with too much pending inflight work

### Diversity and Lease Preferences

After filtering, candidates are further ranked by:
- **Diversity score** — prefer targets that improve locality diversity
- **Lease preference** — when moving a leaseholder, prefer targets matching
  the range's lease preference configuration

See: `cluster_state_rebalance_stores.go`, specifically
`sortTargetCandidateSetAndPick()`.

## Disk Utilization

Disk utilization gets special treatment:

- **Shedding threshold** (default 0.95): stores above this get
  `ReplicaDispositionShedding` — they actively shed replicas.
- **Refuse threshold** (default 0.925): stores above this get
  `ReplicaDispositionRefusing` — they refuse new replicas.
- When a store's disk utilization exceeds the shedding threshold, ByteSize
  becomes the priority dimension for the top-K range selection regardless of
  other load dimensions.
- These thresholds are configured via cluster settings:
  `kv.allocator.max_disk_utilization_threshold` and
  `kv.allocator.rebalance_to_max_disk_utilization_threshold`.

See: `highDiskSpaceUtilization()` in `load.go`, `updateStoreStatuses()` in
`cluster_state.go`.

## Pending Changes and Rate Limiting

MMA tracks pending changes to avoid piling up inaccurate estimates:

- **Per-invocation limits**: 1 replica move, 8 lease transfers per
  `rebalanceStores()` call.
- **Pending fraction threshold** (0.1): if a store's pending decrease fraction
  reaches this, no further shedding from that store.
- **Failed change delay** (60s): ranges with recent failed changes are skipped.
- **Overload grace period** (1 min): after a store drops below overload, wait
  before resetting the overload tracking (prevents oscillation).

See: `newRebalanceEnv()` in `cluster_state_rebalance_stores.go` for the
constant definitions.

## Metrics

All MMA metrics are prefixed with `mma.`. See
`pkg/kv/kvserver/allocator/mmaprototype/mma_metrics.go` for the full
definitions.

### Key Metric Groups

**Store load and capacity** (per-store gauges):
- `mma.store.cpu.{load,capacity,utilization}`
- `mma.store.write.bandwidth`
- `mma.store.disk.{logical,capacity,utilization}`

**Rebalance operations** (per-store counters):
- `mma.change.rebalance.{replica,lease}.{success,failure}` — MMA-initiated
- `mma.change.external.{replica,lease}.{success,failure}` — non-MMA changes

**Overloaded stores** (per-store gauges, by duration bucket):
- `mma.overloaded_store.{lease_grace,short_dur,medium_dur,long_dur}.{success,failure}`

**Other**:
- `mma.dropped` — operations dropped due to state inconsistency
- `mma.external.registration.{success,failure}` — external op registration
- `mma.span_config.normalization.{error,soft_error}` — config issues

## Logging

MMA logs on the `KvDistribution` channel. Most detailed logs are at verbosity
level 2 (`VEventf(ctx, 2, ...)`); candidate-level detail at level 3.

### Key Log Patterns

See `cluster_state_rebalance_stores.go` and `mma_store_rebalancer.go` for the
exact format strings. The important patterns are:

- **Pass start**: `"rebalanceStores begins"`
- **Cluster means**: `"cluster means: (stores-load ...) ..."`
- **Store evaluation**: `"evaluating s%d: node load %s, store load %s, worst dim %s"`
- **Overload transitions**: `"overload-start"`, `"overload-end"`, `"overload-continued"`
- **Shedding store added**: `"store s%v was added to shedding store list"`
- **Skipped (pending)**: `"skipping overloaded store s%d ..."`
- **Top-K ranges**: `"top-K[%s] ranges for s%d ..."`
- **Candidate evaluation**: `"considering replica-transfer r%v from s%v ..."`
- **Failures**: `"result(failed): no candidates found ..."`, `"result(failed): no suitable target ..."`
- **Successes**: `"result(success): ..."`
- **Pass summary**: logged at `Infof` level with shed successes, failures by
  reason, and skipped stores.

The `mmaid` tag is incremented per `rebalanceStores()` call and added to the
context, so all log messages within a single pass share the same `mmaid` value.

## Key Source Files

| File | Description |
|------|-------------|
| `pkg/kv/kvserver/allocator/mmaprototype/doc.go` | Package documentation, links to origin PR |
| `pkg/kv/kvserver/allocator/mmaprototype/allocator.go` | `Allocator` interface definition |
| `pkg/kv/kvserver/allocator/mmaprototype/allocator_state.go` | Top-level state, mutex, `ComputeChanges`, ignore levels and grace period constants |
| `pkg/kv/kvserver/allocator/mmaprototype/cluster_state.go` | Per-store/range/node state, constraint matching, disposition management |
| `pkg/kv/kvserver/allocator/mmaprototype/cluster_state_rebalance_stores.go` | **Core rebalancing algorithm**: `rebalanceStores()`, candidate filtering, lease and replica shedding |
| `pkg/kv/kvserver/allocator/mmaprototype/load.go` | `LoadDimension`, `LoadVector`, `loadSummary` enum, `loadSummaryForDimension()`, means computation, disk utilization checks |
| `pkg/kv/kvserver/allocator/mmaprototype/store_load_summary.go` | `storeLoadSummary` struct |
| `pkg/kv/kvserver/allocator/mmaprototype/mma_metrics.go` | All MMA metric definitions |
| `pkg/kv/kvserver/allocator/mmaprototype/top_k_replicas.go` | Top-K range selection for shedding |
| `pkg/kv/kvserver/allocator/mmaprototype/constraint.go` | Constraint analysis and normalization |
| `pkg/kv/kvserver/allocator/mmaprototype/rebalance_advisor.go` | `MMARebalanceAdvisor` for conflict detection with SMA |
| `pkg/kv/kvserver/allocator/mmaprototype/store_status.go` | Store disposition and health status types |
| `pkg/kv/kvserver/mma_store_rebalancer.go` | Integration: periodic loop, applies changes |
| `pkg/kv/kvserver/mmaintegration/allocator_sync.go` | Coordination between MMA and replicate/lease queues |
| `pkg/kv/kvserver/mmaintegration/store_load_msg.go` | Building `StoreLoadMsg` from store state |
| `pkg/kv/kvserver/mmaintegration/store_status.go` | Building store status updates for MMA |
| `pkg/kv/kvserver/kvserverbase/base.go` | Cluster setting `kv.allocator.load_based_rebalancing` |

## Common Investigation Scenarios

### "Stores are imbalanced on CPU but MMA isn't doing anything"

Check in order:
1. Is MMA enabled? (`kv.allocator.load_based_rebalancing` must be `multi-metric*`)
2. Does MMA see the imbalance? Check `mma.store.cpu.utilization` metrics.
3. Is the overloaded store classified as `overloadSlow` or higher? Check logs
   for `"evaluating s%d"` to see the `storeLoadSummary`.
4. Is the store stuck at pending threshold? Check for `"skipping overloaded store"` logs.
5. Are there viable targets? Check for `"no candidates found"` or
   `"no suitable target"` in logs.
6. Is the store in grace period? Check for `"in lease shedding grace period"`.

### "MMA is rebalancing but the imbalance isn't improving"

Check:
1. Is MMA succeeding? Check `mma.change.rebalance.*.success` vs `*.failure`.
2. Is something else counteracting MMA? Check replicate queue and lease queue
   activity.
3. Is a single hot range causing the imbalance? If so, MMA won't move it if
   it would just shift the problem (candidate filtering prevents this).
4. Are pending change limits preventing more aggressive action? Check the
   `mma.overloaded_store.*` duration buckets — if stores stay in
   `lease_grace` or `short_dur`, MMA is being conservative.

### "Unexpected replica/lease movement"

1. Distinguish MMA moves from queue moves using metrics.
2. Check MMA logs for the specific range movement.
3. Check if the store was classified as overloaded on a dimension you didn't
   expect (e.g., WriteBandwidth might trigger shedding even if CPU looks fine).
