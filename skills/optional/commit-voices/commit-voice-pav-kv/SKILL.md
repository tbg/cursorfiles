---
name: commit-voice-pav-kv
description: Give commit messages Pavel's voice — terse, precise, and unadorned. Use when the user asks to write a commit message "like Pavel would" or in "pav-kv's voice".
---

# Commit Voice — Pavel (pav-kv)

Pavel writes the shortest commit messages on the team. The subject line carries
the message; the body is optional and, when present, rarely exceeds two
sentences. Every word earns its place.

This skill doesn't override mechanical format requirements from other skills
(like `<package>: <verb phrase>` subjects or `Epic:` / `Release note:` lines).
It's about the prose in between.

## The Moves

### Silence as Default

Most of Pavel's commits have no body at all beyond `Epic:` / `Release note:`
lines. If the subject line says it, the body doesn't repeat it.

Subject lines that need no body:

> kvserver: rm unnecessary ReplicaID write

> kvstorage: tighten ReadWriter to Writer

> spanset: rm unused method

> kvserver: use StateEngine in replica_test

> kvserver: shorten receiver name in StateLoader

> server: drive-by style fixup

If you're tempted to write a body for a commit like these, don't.

### The One-Liner

When the subject isn't quite enough, a single sentence of context closes the
gap. No setup, no "Previously", just the fact.

> The field has been deprecated and is now safe to remove.

> The function accesses the Store-local keys used for LoQ recovery.

> The test scans the meta range data, in MVCC keyspace.

> All callers pass in the same opts, so no need in making it configurable.

> The MinVersion needs to be set on both engines.

> The store liveness machinery needs a syncing engine.

> We decided that all Store-local keys are in the log engine.

### Unix Subject Shorthand

Pavel's subjects borrow from Unix and are shorter for it. Use these freely:

- **rm** not "remove"
- **mv** not "move"
- **dd** for "datadriven"
- **plumb** for threading a type through callers
- **annotate** for adding type/comment info
- **clarify** for improving readability
- **squash** for consolidating
- **deflake** for test stability fixes
- **drive-by** for opportunistic cleanup

> kvstorage: rm unused cleared spans return value

> kvserver: mv byte monitoring to raft log file

> kvstorage: annotate RemoveStaleRHSFromSplit

> kvserver: plumb Engines to NewStore

> split: squash datadriven command parsing

### The Dry Observation

When something is wrong or surprising, state it flatly. No exclamation, no
storytelling — just a short factual remark that carries its own weight.

> This seems unintentional.

> This was unnecessarily verbose, error-prone, and led to a bug fixed in the
> previous commit.

> This decision is somewhat arbitrary, but seems logical to use the LogEngine
> as the source of truth for now.

> This at best could lead to a small disk space leak, and at worst a more
> serious bug in replica lifecycle.

### The Precise Technical Paragraph

For genuinely complex changes (race fixes, invariant violations), Pavel writes
a clear, dense technical explanation. Still no filler, no "Previously" preamble,
no "This patch" opener — just jumps straight into what's happening.

> The bug is: we can change the ReplicaID here in storage. And the resulting
> replica will inherit a non-empty HardState that belongs to a different
> ReplicaID.

> We remove the clearing/rewriting of the unreplicated state which belongs to
> that RHS, to let it progress untouched. This also removes a blocker towards
> raft/state-machine storage separation: we don't want to be touching raft
> state of the RHS in the same batch with the state machine updates.

> Keys in the RangeID-local unreplicated space have both state machine and raft
> state. With separated engines, these will reside in different engines, and are
> also interleaved in an unfortunate way. So we can't use one ClearRawRange to
> cover them all, or even one per engine.

> Technically, we must also hold readOnlyCmdMu to set this field, so it fits
> neither of Replica.{mu,shMu} section. But shMu is strictly closer by
> semantics.

### Chain Commits Without Ceremony

Pavel does long refactoring chains (10-30 commits) where each commit is tiny.
He does not signpost future work — the chain speaks for itself. No "future
commits will..." or "in a follow-up we will...". Each commit is self-contained.

### "while here" and "drive-by"

Opportunistic cleanup gets a two-word label, not a paragraph.

> kvserver: drive-by fixups

> while here

### The Motivating Bug

When a preparatory refactoring is motivated by a real problem, Pavel sometimes
explains the concern in a longer `Context:` block. These are rare but thorough
when they appear.

> Context / example of a concern: in replica destruction code
> (kvstorage.DestroyReplica and variants), we should destroy, among other
> things, the "unreplicated" keys. With separated engines this is tricky
> because the raft and state machine keys are inconveniently interleaved.

## Anti-Patterns

Don't do any of these:

- **Writing a body when the subject says it all.** If the commit is `rm unused
  method`, there is nothing to add.
- **"This patch..." / "This commit..."** — Pavel doesn't use these openers.
- **"Previously, ..."** — Pavel doesn't set up the old world. He states what
  the commit does and, optionally, why.
- **"Future commits will..."** — The chain speaks for itself.
- **"Note that..."** — Rare in Pavel's commits. Save it for when it genuinely
  preempts confusion.
- **Padding a one-line change.** If the reason fits in one sentence, that's
  the whole body.
- **Conversational tone.** Pavel's prose is flat and factual, not chatty.
  No dashes for asides, no first-person hedging.
