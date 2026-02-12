---
name: commit-voice-mira
description: Give commit messages Mira's voice — clear, structured, and precise. Use when the user asks to write a commit message "like Mira would" or in "Mira's voice".
---

# Commit Voice — Mira (miraradeva)

Mira writes clean, structured commit messages. She sets up the problem
clearly, explains the fix, and moves on. Her prose is precise without being
terse — she writes enough to make the change fully understandable to a reviewer
who hasn't been following the work.

This skill doesn't override mechanical format requirements from other skills
(like `<package>: <verb phrase>` subjects or `Epic:` / `Release note:` lines).
It's about the prose in between.

## The Moves

### "Previously, ..." → "This commit..."

Mira's backbone structure. She sets up the old state of the world with
"Previously, ...", then pivots to "This commit..." for the fix. The two beats
are usually separate paragraphs.

> Previously, the allocator uses store liveness in addition to node liveness to
> mark a store as suspect. This test overrides the node liveness suspect
> duration from the default 30s to 10s...
>
> This commit overrides the store liveness suspect duration to 10s so it matches
> the node livesness one.

> Previously, non-transactional requests were treated as idempotent by the
> `DistSender`, meaning they were retried in the presence of RPC errors...
>
> This commit treats non-transactional write batches the same way as
> transactional batches that contain a commit.

> Previously, the test assumed epoch leases and had some special logic around
> manipulating node liveness to expire the lease.
>
> This commit extends the test to leader leases.

### "This commit" as the Default Opener

When the change doesn't need a "Previously" setup, Mira opens with "This
commit..." directly. It's her most common sentence starter.

> This commit adds two new roachtests that run a backup over a table with many
> intents.

> This commit adds a new test-only environment variable that disables async
> intent resolution.

> This commit adds logging of some key metrics at the end of each kvnemesis run.

> This commit wraps the lease transfer in a `SucceedsSoon`.

> This commit removes the starting and stopping of the timer.

### "This patch" for Smaller Changes

For lighter changes, Mira sometimes uses "This patch" instead of "This
commit". Both are natural; "This commit" is more frequent.

> This patch adds a field to `observedRead` to indicate that the read should be
> skipped from validation if rolled back by a savepoint.

> This patch uses `FindRangeLeaseEx` instead of `FindRangeLeaseHolder` to find
> the lease.

### Structured Descriptions for Bigger Changes

For complex changes, Mira writes multiple clear paragraphs, each covering a
distinct aspect. She uses bullet points or numbered lists when there are
multiple variants or items to enumerate, and backtick-formats code identifiers.

> This commit adds the following CPut operations to kvnemesis:
>
> - `CPutMatchExisting`: the CPut condition matches an existing key's value.
> - `CPutMatchMissing`: the CPut condition matches a missing key's nil value.
> - `CPutNoMatch`: the CPut condition is not satisfied and the request fails.
> - `CPutAllowIfDoesNotExist`: the CPut condition is not satisfied but the
>   operation succeeds if the value does not exist.

> - Safety mode: all fault patterns are allowed; unavailability errors are
>   ignored.
> - Liveness mode: faults are introduced carefully to ensure a well-connected
>   quorum is preserved; unavailability errors fail the test.

### Deflake Commits with Clear Causation

Mira's deflake commits explain the race or timing issue cleanly, then describe
the fix. She identifies what changed to make the test flaky and connects it to
the mechanism of the failure.

> The test relies on a successful lease transfer to prove an abandoned follower
> can be brought back. But the lease transfer can race with the follower
> receiving a snapshot, which currently fails the lease transfer (because the
> replica is in `StateSnapshot`).
>
> This commit wraps the lease transfer in a `SucceedsSoon`.

> When running with leader leases, it might take an extra election timeout for
> the leader lease to be established after adding the new voters, so the test
> flaked if the re-computation ran (and failed) before the leaseholder was
> ready.
>
> This commit makes the test retry the re-computation until a leaseholder is
> established.

### Qualifying Notes

Mira adds qualifiers when the change has limitations, side effects, or is
deliberately scoped. These are factual and measured.

> The downside is that the benchmark now also measures the allocations as part
> of `makeBuffer`.

> The new logic is currently behind an off-by-default cluster setting as it
> will require deflaking many tests. The plan is to enable this in some
> kvnemesis tests first.

> It's not clear what changed but these don't cause the tests to fail anymore
> (or at least it's hard to repro). Potentially, the theory for why they could
> fail was not quite right. Will investigate more if they fail in CI.

> This issue is known and documented in the `DistSender` code. It is not a
> production correctness issue since SQL always uses the transactional KV API.

### "While here, ..."

Drive-by improvements tucked in with the main change.

> While here, also bump up the max warehouses for some tests that have failed
> recently.

### Technical Context Without Over-Explaining

Mira provides enough context for reviewers to understand why the change matters
without repeating what they can see in the diff. She references issues, PRs,
and specific commits when they provide important background.

> Since this commit was introduced, we've addressed the underlying backoff
> issue within kvnemesis (#137092). We don't need the backoff for all users of
> the `db.Txn` API.

> This became evident from the last remaining case
> (failover/non-system/blackhole-recv) where the failover duration of
> expiration leases was a little better than leader leases (see #133612).

## Anti-Patterns

Don't do any of these:

- **Skipping "Previously, ..." for non-trivial changes.** Mira's commits are
  clear because they set up the context before the fix.
- **Dropping "This commit".** It's the default opener. Don't replace it with
  bare verbs or "Here, ...".
- **Being chatty or first-person.** Mira doesn't use "I" in commit messages.
  The tone is clear and professional, not conversational.
- **Overusing hedging language.** Mira states what the change does directly.
  She adds qualifiers only when there's a genuine limitation or uncertainty.
- **Skipping code formatting.** Mira backtick-formats identifiers, settings,
  and error names consistently.
