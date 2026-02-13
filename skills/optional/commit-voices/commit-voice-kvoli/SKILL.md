---
name: commit-voice-kvoli
description: Give commit messages Austen's voice — clear, grounded, and structured around motivation. Use when the user asks to write a commit message "like Austen would", "as kvoli would", or in "kvoli's voice".
---

# Commit Voice — Austen (kvoli)

Austen writes commit messages that are clear and well-motivated. He leads
with *why* the change exists — grounding it in observable behavior, design
goals, or operational context — then describes what the commit does. His
prose sits between casual and formal: professional but not stiff, concise
but not curt. He uses "we" naturally, structures multi-part changes with
bullet points, and isn't afraid to explain the tradeoff he chose.

This skill doesn't override mechanical format requirements from other skills
(like `<package>: <verb phrase>` subjects or `Epic:` / `Release note:` lines).
It's about the prose in between.

## The Moves

### "Previously, ..." → Fix

Austen's backbone structure. He sets up the old state of the world with
"Previously, ..." then describes what this commit changes. The transition
is clean — usually a paragraph break.

> Previously, the allocator would consider all stores as potential
> rebalance targets, including stores that already had a replica for the
> range. This could result in no-op rebalance operations that consumed
> snapshot bandwidth without improving balance.
>
> Filter out stores that already hold a replica before scoring candidates.

> Previously, the store rebalancer would compute load-based rebalance
> candidates using point-in-time load metrics. These metrics could be
> stale by the time the rebalance operation was executed, leading to
> thrashing between stores.
>
> Use a smoothed load signal that averages over a configurable window.

> Previously, the simulator would configure all stores identically
> regardless of the workload distribution. This made it difficult to
> test heterogeneous cluster scenarios.

### "This patch..." as Default Opener

When the change doesn't need a "Previously" setup, Austen leads with
"This patch" and an active verb.

> This patch introduces per-store CPU load tracking to the allocator,
> allowing rebalancing decisions to account for compute utilization
> alongside QPS and write bytes.

> This patch refactors the `ReplicateQueue` scoring logic to separate
> constraint satisfaction checks from load-based scoring.

> This patch adds a data-driven test for the store rebalancer that
> exercises the full rebalancing loop with configurable store loads.

> This patch wires the allocator simulator into the roachtest framework,
> allowing simulated rebalancing scenarios to be run as part of CI.

### Motivation Before Mechanism

Austen explains *why* before *what*. He connects the change to a design
goal, a user-visible problem, or a gap in the current behavior.

> The allocator currently treats CPU and QPS as independent signals, but
> in practice they're correlated. This leads to redundant rebalancing
> when both signals point to the same store as overloaded.
>
> Unify the signals into a single composite score.

> Rebalancing decisions that rely solely on replica count can leave
> clusters unbalanced when workload is skewed. A store with 100 idle
> replicas looks equivalent to one with 100 hot replicas.

> Without a way to simulate allocator behavior offline, every change to
> rebalancing heuristics requires expensive roachtest validation.

### "We" as Default Pronoun

Austen uses "we" for the codebase, the team, and the reader. It's
inclusive and conversational without being sloppy.

> We now track per-store CPU usage and expose it through the
> `StoreCapacity` proto.

> We don't want to rebalance away from a store that's only temporarily
> hot — the smoothing window prevents this.

> We use the mean absolute deviation as the measure of balance, since
> standard deviation overweights outliers in small cluster sizes.

> We previously relied on the gossip network for store descriptors, but
> this was racy during rapid membership changes.

### Structured Lists for Multi-Part Changes

Austen uses dashed bullet points to enumerate the pieces of a
multi-part change. Each item is a concise description.

> This patch does the following:
>
> - Introduces a `LoadDimension` enum (`QPS`, `CPU`, `WriteBytesPerSec`)
>   to replace the implicit load type selection.
> - Refactors the `CandidateList` scoring to accept a `LoadDimension`.
> - Updates the `StoreRebalancer` to select the load dimension based on
>   the cluster setting `kv.allocator.load_based_rebalancing.objective`.
> - Adds unit tests for each dimension.

> Changes:
>
> - Add `--cpu-profile` flag to the asim CLI.
> - Collect per-tick CPU samples in the simulator state.
> - Emit a summary table at the end of simulation runs.

### "e.g." and Parenthetical Examples

Austen drops in inline examples to make abstract concepts concrete.

> The allocator considers multiple signals (e.g. QPS, CPU, disk
> utilization) when scoring candidate stores.

> Some workloads produce asymmetric load distributions (e.g. a single
> hot range receiving 90% of writes) that the mean-based scorer handles
> poorly.

> The existing datadriven format uses raw nanoseconds for CPU capacity
> (e.g. `node_cpu_rate_capacity=8000000000`), which is error-prone.

### "For now, ..." for Deliberate Scoping

When the change is one step in a larger effort, Austen signals that
with "For now" and often mentions what comes next.

> For now, we only consider CPU when the cluster setting is explicitly
> set. A follow-up will make it the default.

> For now, the simulator does not model snapshot transfers. This is
> a known limitation that will be addressed separately.

> For now, this is behind a feature flag. We'll enable it by default
> once the roachtest suite passes cleanly.

### The Honest Tradeoff

Austen acknowledges when a choice is imperfect and explains why it's
the right call anyway.

> Using a simple moving average is less responsive than exponential
> smoothing, but it's easier to reason about and the allocator doesn't
> need sub-second granularity.

> This duplicates some logic from the allocator, but keeping the
> simulator's scoring self-contained makes it easier to validate in
> isolation.

> Ideally we'd compute this lazily, but the hot path needs it on every
> tick and the allocation overhead is negligible.

### The Concise One-Liner

For small fixes, cleanup, or mechanical changes, one sentence is enough.

> The field was renamed but the test assertion wasn't updated.

> This was a copy-paste error from the QPS-based scorer.

> Alphabetize the metrics for consistency with the rest of the file.

> Remove dead code left over from the pre-MMA allocator.

### "While here, ..."

Opportunistic improvements bundled with the main change.

> While here, also rename `shouldRebalance` to `shouldRebalanceStore`
> to distinguish it from the range-level method.

> While here, fix a comment that was referencing the old field name.

### Benchmark and Simulation Evidence

When a change affects rebalancing behavior, Austen includes simulation
output or roachtest results to demonstrate the impact.

> Simulation results (3-node, 10k ranges, skewed write workload):
>
> ```
> metric              before    after     delta
> balance_score       0.42      0.18      -57%
> rebalance_ops       312       187       -40%
> convergence_time    8m12s     4m47s     -42%
> ```

> The roachtest `rebalance/by-load/cpu` now converges in ~5 minutes
> instead of timing out at 10.

## Structural Patterns

Austen's commits often use these structural elements:

- **"Previously, ..."** setups followed by the fix
- **"This patch..."** openers with active verbs
- **"We"** as the pervasive pronoun
- **Dashed bullet lists** for multi-part changes
- **Parenthetical examples** with "e.g." to ground abstractions
- **"For now, ..."** to signal deliberate scoping
- **Simulation/benchmark data** for rebalancing changes
- **Motivation before mechanism** ordering

## Anti-Patterns

Don't do any of these:

- **Using "This commit..." or "This change...".** Austen says "This patch".
- **Using "I".** Austen uses "we" almost exclusively.
- **Skipping the motivation.** Austen explains why before what. Don't lead
  with the mechanism if the reader doesn't yet know why it matters.
- **Using numbered lists.** Austen uses dashes for enumeration.
- **Being terse for complex changes.** Austen builds context. A one-liner
  body is fine for a one-liner fix, not for a rebalancing heuristic change.
- **Omitting tradeoffs.** If there's a simpler or more correct alternative
  you didn't take, mention it and explain why.
- **Hiding simulation results.** If the change affects rebalancing behavior,
  show the numbers.
