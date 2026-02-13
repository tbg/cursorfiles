---
name: commit-voice-andreimatei
description: Give commit messages Andrei's voice — direct, opinionated, and surgically precise. Use when the user asks to write a commit message "like Andrei would", "as andreimatei would", or in "Andrei's voice".
---

# Commit Voice — Andrei (andreimatei)

Andrei writes commit messages that cut straight to the point. His prose is
spare and opinionated — he says what's wrong, why it's wrong, and what this
commit does about it, often in that order. He doesn't pad, doesn't hedge
when he's sure, and doesn't soften criticism of existing code. When something
is a mess, he says so. When the fix is simple, the message is short. His
technical explanations are surgically precise: he isolates the exact mechanism
of a bug or design flaw and describes it in concrete terms.

This skill doesn't override mechanical format requirements from other skills
(like `<package>: <verb phrase>` subjects or `Epic:` / `Release note:` lines).
It's about the prose in between.

## The Moves

### The Blunt Diagnosis

Andrei's most distinctive move. He identifies what's wrong and states it
plainly, without diplomatic softening. The problem is the subject.

> The tracing infrastructure was leaking goroutines because `Span.Finish()`
> was not being called on error paths. This was masked in tests because
> the test-only tracer didn't enforce cleanup.

> The RPC layer was double-serializing the `BatchRequest` header — once
> in the `SendNext` loop and again in the transport. The second
> serialization was wasted work.

> The error handling here was broken: errors from `db.Txn()` were being
> swallowed, so callers had no way to distinguish a commit failure from
> a successful commit.

> This was wrong. The `gateway` field is the node that received the
> original SQL query, not the node that's currently evaluating the
> request. Using it for anything related to data locality is a bug.

### Short, Punchy Sentences

Andrei favors short declarative sentences. He rarely writes compound
sentences where two simple ones would do.

> This was a no-op. Remove it.

> The context was being canceled too early. The RPC had not yet completed.

> This field was unused. It was added speculatively in 2019 and never
> wired up.

> Fix the test. The assertion was backwards.

### Imperative Mood for the Fix

After diagnosing the problem, Andrei states the fix in imperative mood —
often as its own sentence or paragraph.

> Remove the redundant serialization.

> Move the `Span.Finish()` call to a defer.

> Stop swallowing the error.

> Propagate the context correctly through the RPC layer.

> Delete the dead code.

### Calling Out Design Flaws

Andrei is direct about design problems in existing code. He doesn't hide
behind "this could be improved" — he says what's wrong and often why it
ended up that way.

> The entire `rowexec` error handling strategy is fundamentally broken.
> Errors are propagated through a mix of return values, panics, and
> channel sends, with no consistent contract about which path a given
> error will take.

> The way we set up tracing contexts is wrong. We create a root span
> for the SQL statement, then create child spans for each RPC, but
> there's nothing tying the child span's lifetime to the RPC's
> lifetime. If the RPC fails, the child span leaks.

> This interface exists because of a historical accident: the SQL and KV
> layers were originally in the same package, and the interface was
> introduced as a refactoring boundary. It serves no purpose now.

### The Flat Observation

When something is surprising, wrong, or interesting, Andrei states it
flatly. No exclamation, no buildup — just the fact.

> This has been broken since 2021.

> Nobody calls this function.

> The comment says "must not be nil" but half the callers pass nil.

> The test passes for the wrong reason.

### "In particular, ..."

Andrei uses "In particular" to zoom in on the specific detail that
matters within a broader context.

> The tracing code was creating spans in several places without proper
> cleanup. In particular, the `execFactory` was creating a span for each
> operator but only finishing it if the operator completed without error.

> Contexts were being mismanaged across the RPC boundary. In particular,
> the server-side handler was using the client's context instead of
> creating its own, which meant canceling the client's request would
> kill in-flight work on the server.

### Terse Subjects for Cleanup

Andrei's cleanup commits have tight subjects and no body. The subject
says what was done; the diff shows what was removed.

> sql: remove unused `planNode.Close` return value

> util/tracing: delete dead `Tracer.StartChildSpan` code path

> kv: drop redundant nil check in `DistSender.Send`

> rpc: unexport `Context.GRPCDialOptions`

### First Person When Warranted

Andrei uses "I" sparingly — when describing something he investigated
or a judgment call he made. It's never casual; it's precise.

> I tracked this down to a race between `Span.Finish()` and
> `Span.SetTag()`: if `SetTag()` is called after `Finish()`, the tag
> is written to a recycled span object.

> I'm not sure this is the right long-term fix, but it stops the
> bleeding.

### The One-Sentence Body

For non-trivial but straightforward changes, one sentence bridges the
gap between the subject and the diff.

> The old code path was quadratic in the number of spans.

> The field was only read in tests.

> This matches what the other callers already do.

> The goroutine was blocked forever because the channel was unbuffered
> and the sender had exited.

### The Unflinching "This is wrong"

When something violates correctness, Andrei says so without qualifiers.
He doesn't write "this may cause issues" — he writes what *will* happen.

> This will corrupt the tracing output if two RPCs race on the same span.

> This violates the contract of `context.WithCancel`: the cancel function
> must be called exactly once, but this code path calls it zero times.

> This causes a goroutine leak every time the RPC times out.

### Backtick Formatting

Andrei formats code identifiers with backticks — functions, types,
fields, error names. He uses the short name unless ambiguity requires
the full path.

> `Span.Finish()`

> `DistSender.Send`

> `BatchRequest.Header`

## Anti-Patterns

Don't do any of these:

- **Being diplomatic about broken code.** Andrei says "this was wrong" or
  "this was broken", not "this could be improved".
- **Padding with "This commit..." or "This patch..." openers.** Andrei
  jumps into the problem or the fix directly.
- **Using "Previously, ..." or "Currently, ...".** Andrei describes the bug
  or flaw directly, in present or past tense.
- **Hedging when you're sure.** Don't write "this may cause issues" when
  you know it causes a goroutine leak. State the consequence.
- **Writing multiple paragraphs for a one-line fix.** If the fix is
  obvious from the subject, the body is one sentence or absent.
- **Using "we" generically.** Andrei uses "I" when it's his investigation
  and bare statements when describing the code. He doesn't use "we" as
  a soft "I".
- **Softening criticism.** If the design is fundamentally broken, say so.
  The commit message is the place to be honest about the state of things.
- **Skipping the mechanism.** Don't just say "fix bug". Describe the exact
  sequence of events that causes the bug.
