---
name: commit-voice-nvb
description: Give commit messages Nathan's voice — formal, impersonal, and built on correctness reasoning. Use when the user asks to write a commit message "like Nathan would", "as nvb would", or in "nvb's voice".
---

# Commit Voice — Nathan (nvb)

Nathan writes commit messages that read like miniature technical papers.
His prose is impersonal and formal — he never uses "I" and rarely uses "we"
except when describing team decisions. The hallmark of his style is rigorous
correctness reasoning: he explains *why* a change is safe, not just what it
does. For complex changes, he structures descriptions with clear sections,
numbered invariants, and precise references to concurrency semantics.

This skill doesn't override mechanical format requirements from other skills
(like `<package>: <verb phrase>` subjects or `Epic:` / `Release note:` lines).
It's about the prose in between.

## The Moves

### "This change..." / "This commit..." as Default Opener

Nathan's default sentence starter. He states what the commit does in third
person, impersonal voice.

> This change introduces a new `lockTableWaiter` structure that encapsulates
> the logic for waiting on conflicting locks during request evaluation.

> This commit fixes a bug in the concurrency manager where a request could
> be admitted to evaluate despite holding insufficient latches.

> This change teaches the lock table to track finalized transactions so
> that conflicting locks held by finalized transactions can be resolved
> without redundant discovery.

> This commit restructures the `txnPipeliner` to separate its role as a
> lock footprint tracker from its role as a write pipeline manager.

### The Correctness Argument

Nathan's most distinctive move. When a change touches concurrency or
transaction semantics, he explains why the change preserves correctness.
He reasons about invariants, ordering guarantees, and edge cases explicitly.

> This is safe because the lock table's internal sequence number is always
> monotonically increasing, and a request that has already been sequenced
> will never be re-sequenced at a lower sequence number.

> The correctness of this approach relies on the fact that a transaction's
> write timestamp can only move forward, never backward. As a result, a
> read that observes a write at timestamp T is guaranteed to also observe
> that write at any timestamp T' > T.

> This does not introduce a correctness issue because the latch manager
> already ensures mutual exclusion between overlapping requests. The lock
> table provides additional fairness guarantees, but these are not required
> for correctness — only for preventing starvation.

### The Invariant Statement

Nathan names and describes invariants explicitly, often with formatting
that makes them stand out.

> The key invariant is: a lock is never removed from the lock table while
> a request that discovered the lock is still waiting in the lock's wait
> queue.

> This relies on an invariant maintained by the `txnWaitQueue`: a
> transaction is only ever added to the queue once, and its entry is
> removed only after the transaction is finalized.

> Invariant: if a request holds latches, it must be the case that its
> evaluation has been authorized by the concurrency manager.

### Precise Decomposition for Large Changes

For substantial PRs, Nathan numbers the components of the change. Each
numbered item is a self-contained description.

> This change does the following:
>
> 1. Introduces a `lockTableGuard` interface that abstracts the lock
>    table's role in the concurrency manager.
> 2. Refactors the `concurrencyManager.sequenceReq` method to use the
>    new interface.
> 3. Adds unit tests for the new interface.

> The change is broken into three parts:
>
> 1. The `lock.Strength` type is introduced to model shared and exclusive
>    lock strengths.
> 2. The lock table is taught to track shared locks alongside exclusive
>    locks.
> 3. The concurrency manager is updated to acquire shared locks for
>    non-locking reads under serializable isolation.

### "Note that..." to Preempt Questions

Nathan uses "Note that" to address things a reviewer might wonder about.
These preempt confusion without being chatty.

> Note that this change does not affect the behavior of non-transactional
> requests, which continue to bypass the lock table entirely.

> Note that the lock table already handled this case for exclusive locks;
> this change extends the same logic to shared locks.

> Note that this is a no-op in the common case — the fast path avoids
> the allocation entirely.

### The Problem Statement Before the Solution

Nathan describes the problem space precisely before introducing the fix.
He doesn't jump to the solution.

> When a transaction is pushed to a higher timestamp, its in-flight writes
> may conflict with reads that were performed at a timestamp between the
> original and pushed timestamps. The concurrency manager currently does
> not account for this, which can lead to stale read results under
> certain interleaving patterns.
>
> This change addresses the issue by...

> The `DistSender` currently sends `QueryIntent` requests in parallel with
> the `EndTxn` request. If the `QueryIntent` discovers that an intent has
> been resolved (e.g. by a concurrent transaction recovery), it returns
> an ambiguous result. The `EndTxn` then fails because the transaction
> record has already been finalized.

### Backtick Formatting for Identifiers

Nathan consistently formats Go types, functions, fields, and package names
with backticks. He uses the full qualified name when ambiguity is possible.

> The `lockTable.ScanAndEnqueue` method...

> The `concurrency.Guard` returned by `Manager.SequenceReq`...

> The `kv.Txn.ReadTimestamp` field...

### Impersonal Voice Throughout

Nathan never writes "I" and avoids "we" except for team-level statements
("we decided", "we now require"). The code and system are the subjects.

> The lock table is modified to...

> The concurrency manager now guarantees that...

> Requests that hold latches are prevented from...

Not:

> I modified the lock table to...

> We now guarantee that...

### Links to Design Documents and RFCs

For changes that implement designs, Nathan links to the design document
or RFC. He treats the link as essential context, not optional.

> This change is part of the shared locks project described in the lock
> table design RFC[^1].
>
> [^1]: https://github.com/cockroachdb/cockroach/blob/master/docs/RFCS/...

> See the transaction pipelining RFC for background on why this batching
> is necessary.

### "Fixes #..." / "Informs #..." / "Closes #..."

Nathan uses issue verbs precisely:

- **Fixes #XXXX** — the commit resolves a bug.
- **Closes #XXXX** — the commit completes the issue.
- **Informs #XXXX** — the commit is related but doesn't close it.
- **Part of #XXXX** — the commit is one step in a larger effort.

### Short Subjects for Refactoring Chains

Nathan writes long refactoring chains where each commit has a tight subject
and minimal body. The chain's structure tells the story.

> concurrency: extract lockTableWaiter from concurrencyManager

> concurrency: introduce lock.Strength type

> concurrency: teach lockTable to track shared locks

> kv: plumb lock strength through BatchRequest

## Structural Patterns

Nathan's commits often use these structural elements:

- **Numbered invariants** that are named and referenced
- **Backtick-formatted identifiers** throughout
- **"Note that..."** asides to preempt reviewer questions
- **"This change..."** openers followed by the mechanism
- **Design doc / RFC links** for project-level changes
- **Precise issue verbs** (Fixes, Closes, Informs, Part of)

## Anti-Patterns

Don't do any of these:

- **Using first person.** Nathan never writes "I". He occasionally uses "we"
  for team decisions, but the code and system are the default subjects.
- **Skipping the correctness argument.** If the change touches concurrency
  or transaction semantics, explain why it's safe.
- **Being chatty or conversational.** Nathan's tone is formal and precise.
  No asides, no humor, no hedging language.
- **Leaving invariants implicit.** If an invariant matters, name it and state
  it explicitly.
- **Skipping backtick formatting.** Types, functions, fields, and packages
  are always formatted with backticks.
- **Jumping to the fix.** Nathan describes the problem space first, then the
  solution. Don't reverse the order.
- **Using "Previously, ..."** Nathan doesn't set up the old world with this
  framing. He describes the current state or the problem directly.
- **Padding trivial changes.** A rename or deletion gets a tight subject and
  no body.
