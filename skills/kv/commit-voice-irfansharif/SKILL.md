---
name: commit-voice-irfansharif
description: Give commit messages Irfan's voice — methodical, inclusive, and layered with context. Use when the user asks to write a commit message "like Irfan would", "as irfansharif would", or in "Irfan's voice".
---

# Commit Voice — Irfan (irfansharif)

Irfan writes commit messages that build understanding incrementally. He sets
up context methodically, often walking through the system's current behavior
before introducing the change. His default pronoun is "we" — both for
describing the codebase's behavior and for team decisions. His prose is clear
and organized, with bullet points and structured sections for complex changes.

This skill doesn't override mechanical format requirements from other skills
(like `<package>: <verb phrase>` subjects or `Epic:` / `Release note:` lines).
It's about the prose in between.

## The Moves

### "This patch..." as Default Opener

Irfan's most common sentence starter. He leads with "This patch" and an
active verb.

> This patch introduces admission control for replicated writes at the
> follower level, gating admission on the size of the unapplied raft log.

> This patch removes the unused `replicaFlowControlIntegration` interface
> and consolidates the remaining logic into the `Replica` type directly.

> This patch threads per-store admission control state through the
> `StorePool`, making it available to the allocator during rebalancing
> decisions.

> This patch adds a `kvflowcontrol.Handle` to each `Replica`, used to
> interface with the flow control machinery for replication admission.

### "Prior to this patch, ..." → "This patch..."

Irfan's two-beat structure for changes that fix or replace behavior.
He sets up the old world with "Prior to this patch" and pivots to
"This patch".

> Prior to this patch, the allocator would not consider IO overload when
> making lease transfer decisions. This meant that a store with high IO
> overload could continue to accumulate leases, exacerbating the problem.
>
> This patch teaches the allocator to factor in IO overload when evaluating
> lease transfer candidates.

> Prior to this patch, we'd use a fixed 1MiB/s rate for recovery
> snapshots, regardless of available bandwidth. This patch makes the rate
> configurable via a cluster setting and defaults it to a higher value.

> Prior to this patch, the flow control machinery only tracked the
> aggregate `log_entries_bytes` without distinguishing between regular
> and elastic work. This patch introduces per-priority tracking.

### "We" as Default Pronoun

Irfan uses "we" pervasively — to describe the codebase's behavior,
team decisions, and the reader-writer relationship. It creates an
inclusive, collaborative tone.

> We now deduct flow tokens at the point of proposal, and return them
> when the proposal is admitted on the receiving end.

> We want to pace admission of elastic work below the rate at which
> regular work is being admitted.

> We use this to determine whether a given store is potentially
> overloaded from an IO perspective.

> We don't want to block replicated writes indefinitely; we'd rather
> shed load at the KV level than let the raft log grow without bound.

### Structured Lists for Multi-Part Changes

Irfan uses bullet points (dashes) to enumerate components of a change
or dimensions of a problem. He uses them more than any other format.

> This patch does the following:
>
> - Introduces `kvflowcontrol.Tokens` as a typed wrapper around `int64`
>   to represent flow control tokens.
> - Adds `kvflowcontrol.Stream` to identify the per-store, per-priority
>   flow of tokens.
> - Wires the `Handle` into `Replica` proposal handling.
> - Adds end-to-end integration tests.

> The allocator now considers the following when making rebalancing
> decisions:
>
> - CPU usage per store, normalized by the number of cores.
> - IO overload score, derived from LSM L0 sub-level count and
>   compaction debt.
> - Disk utilization, as a fraction of total capacity.

### "In doing so, ..."

Irfan uses this phrase to describe a secondary effect or consequence
of the main change.

> In doing so, we also simplify the `replicaFlowControlIntegration`
> interface by removing methods that are no longer needed.

> In doing so, this patch also fixes a bug where the token return
> callback was invoked twice for the same proposal.

### "---" Separators in Long PR Descriptions

For complex PRs, Irfan uses horizontal rules to separate sections of
the description — motivation, description, testing, future work.

### Benchmark Data as Evidence

When the change has performance implications, Irfan includes benchmark
results. He provides context about the benchmark setup and what to look
for in the numbers.

> Running `kv0/enc=false/nodes=3/cpu=8` with this patch:
>
> ```
> name          old ops/s    new ops/s    delta
> kv0-read      45,291       45,102       -0.42%
> kv0-write     12,847       14,203       +10.55%
> ```
>
> The write throughput improvement is expected — we're no longer blocking
> proposals while waiting for flow tokens under light load.

### "Note:" for Important Asides

Irfan uses "Note:" (capitalized, with colon) for information that
doesn't fit in the main narrative but matters for reviewers.

> Note: this patch does not yet wire up the elastic token bucket. That
> will follow in a subsequent PR.

> Note: the admission control integration is gated behind a cluster
> setting that defaults to off for now.

### "For now, ..." for Deliberate Scoping

When the change is intentionally limited, Irfan says so with "For now"
and often mentions what will follow.

> For now, we only consider L0 sub-level count as the IO overload
> signal. We can extend this to include compaction debt and write
> amplification in the future.

> For now, flow tokens are returned synchronously on the proposing
> replica. A follow-up will move this to the apply loop.

### Reference Links for Context

Irfan links to design documents, related PRs, and issues to provide
background without cluttering the commit message itself.

> See the flow control RFC[^1] for the full design.
>
> [^1]: https://github.com/cockroachdb/cockroach/blob/master/docs/RFCS/...

> This is part of the broader replication admission control effort
> tracked in #95563.

### "This is because..." for Explanations

Irfan connects causes to effects explicitly.

> This is because the flow control handle outlives the proposal — it
> needs to remain valid until the entry is admitted on the follower.

> This is because the allocator snapshot is captured at the beginning
> of the rebalancing loop, and the IO overload score can change between
> iterations.

## Structural Patterns

Irfan's commits often use these structural elements:

- **"This patch..."** openers with active verbs
- **"Prior to this patch, ..."** for before/after framing
- **"We"** as the pervasive pronoun
- **Dashed bullet lists** for multi-part changes
- **"Note:"** asides for reviewer-directed information
- **"For now, ..."** to signal deliberate scoping
- **"---"** horizontal rules in longer PR descriptions
- **Benchmark data** with setup context

## Anti-Patterns

Don't do any of these:

- **Using "This commit..." or "This change...".** Irfan says "This patch".
- **Using "I".** Irfan uses "we" almost exclusively. First person singular
  is rare.
- **Skipping the "Prior to this patch" setup.** For non-trivial changes,
  Irfan always describes the old behavior before the new.
- **Using numbered lists.** Irfan prefers dashes for enumeration.
- **Being terse for complex changes.** Irfan builds understanding
  incrementally. Don't skip context that helps the reviewer follow along.
- **Omitting future work signals.** If the change is one step in a larger
  effort, say so with "For now, ..." or a tracking issue reference.
- **Using "Previously, ..."** Irfan uses "Prior to this patch, ..." to set
  up the old world.
