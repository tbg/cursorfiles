---
name: commit-voice-5hubh4m
description: Give commit messages Shubham's voice — casual, direct, and concise with a conversational first-person tone. Use when the user asks to write a commit message "like Shubham would" or in "Shubham's voice".
---

# Commit Voice — Shubham (5hubh4m)

Shubham writes commit messages that are casual and to the point. His
bodies are short — often just one to three sentences — and he's
comfortable using first person. He leans toward past tense in subject
lines ("added", "made", "updated") more than imperative, and his tone
is conversational, with parenthetical asides and honest admissions
about the work.

Note: this skill was synthesized from a limited dataset (~17 commits).
The patterns below are real but may evolve as more commits accumulate.

This skill doesn't override mechanical format requirements from other
skills (like `<package>: <verb phrase>` subjects or `Epic:` / `Release
note:` lines). It's about the prose in between.

## The Moves

### Past Tense in Subject Lines

Shubham favors past tense over imperative in subject lines, which is
unusual on the team.

> asim: added more asim tests to check constraint satisfaction

> asim: added conformance assertions to constraint satisfaction asim
> tests

> roachtest: added MMA+count rebalance tests

> roachtest: made rebalance_load tests more concise

> asim: updated CPU loads in test one_voter_skewed_cpu_skewed_write

Imperative occasionally appears for short fixes:

> asim: fix some nits in the constraint satisfaction asim tests

### Short Bodies

Most commit bodies are one to three sentences. Shubham states what the
commit does and why, then stops.

> Add a store ID tag to the context passed to ProcessStoreLoadMsg call
> for better logging.

> Add load and capacity related metrics to observe exactly what MMA
> sees instead of having to perform backwards calculations from raw
> data.

> Linux has a soft limit on username lengths of 32. This change makes
> `scripts/gceworker.sh` manually trim the usernames to 32 when
> generating SSH configs.

### First Person, Casually

Shubham uses "I" freely and without ceremony.

> Did some experimenting with MMA and disk balancing and added these 3
> asim tests.

> Some comments in my previous PR (#161078) weren't terminated by
> periods, so I fixed that.

> CPU params `request_cpu_per_access` and `raft_cpu_per_write` were too
> low, I updated them to generate more realistic CPU loads and verified
> MMA behaviour against these params.

### "Currently, ..." for Refactoring Context

When refactoring, Shubham borrows the "Currently" setup to describe
the status quo.

> Currently, the rebalance_load tests were added one-by-one with a lot
> of code duplication. I coalesced all of them by two parameters:
> rebalanceMode and testKind and made the logic of choosing parameters
> for the tests (hopefully) more clear, reducing code duplication.

### Parenthetical Asides

Shubham drops in parenthetical qualifiers naturally.

> (hopefully) more clear

### Numbered Lists for Multiple Items

When a commit adds several distinct things, Shubham lists them.

> Did some experimenting with MMA and disk balancing and added these 3
> asim tests.
>
> 1. Single-node/multi-store balancing
> 2. Multi-node setup with a write-only workload targeting nodes
>    unevenly
> 3. Multi-node setup with imbalanced disk usage with a write-only
>    workload targeting all nodes evenly

### "This change..." / "This set of commits..."

Shubham occasionally uses "This change" or "This set of commits" as
an opener, though it's not his default.

> This change makes `scripts/gceworker.sh` manually trim the usernames
> to 32 when generating SSH configs.

> This set of commits completes the TODOs in asim tests [...], so these
> should be removed.

### No Body for Trivial Changes

For nit fixes or small updates, the subject line is enough.

> asim: fix some nits in the constraint satisfaction asim tests
>
> Release note: None

## Anti-Patterns

Don't do any of these:

- **Being impersonal.** Shubham uses "I" and "my" naturally. Don't
  write in passive voice or avoid first person.
- **Using "This commit..." or "This patch...".** Shubham either uses
  "This change..." or just states what he did directly.
- **Over-explaining.** Shubham's bodies are short. Don't write three
  paragraphs when two sentences will do.
- **Using imperative subjects exclusively.** Shubham defaults to past
  tense ("added", "made", "updated") in subject lines.
- **Being formal.** Shubham's tone is casual and conversational. Don't
  write like a technical report.
