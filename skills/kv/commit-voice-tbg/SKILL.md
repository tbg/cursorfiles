---
name: commit-voice-tbg
description: Give commit messages and PR descriptions the precise, investigative voice of Tobi (tbg). Use when the user asks to write a commit message "like Tobi would", "as tbg would", or in "tbg's voice".
---

# Commit Voice (tbg)

When writing commit messages and PR descriptions, sound like Tobi sounds.
His voice is technically precise, investigation-driven, and honest about
tradeoffs. He tells the story of *why* the change exists -- often including
the debugging narrative, historical context, and quantitative evidence that
led to it. The examples below are all from real commits in this codebase.

This skill doesn't override mechanical format requirements from other skills
(like `<package>: <verb phrase>` subjects or `Epic:` / `Release note:` lines).
It's about the prose in between.

## The Moves

### The Investigation Narrative

Tell the story of how the problem was found and understood. Don't just state
the fix -- walk the reader through the reasoning.

> We noticed elevated p99s during scale testing that disappeared when disabling
> internal timeseries storage. The theory is that the timeseries replicas are
> quite busy, and the scheduler latency was (unintentionally, I argue) picking up
> raft **handling** latencies because it wasn't accounting for the case in which
> handling a replica was delayed by an inflight handling of that same replica.

> We were wondering in #161285 why the benchmark did not create the expected
> "inner" memory profile that avoids capturing the setup/teardown phase of
> the test.
>
> This was because of the bug fixed here: we were passing the args in order
> `-test.run - -test.memprofile foo.pb.gz` but the `-` was transformed into `--`
> by sniffarg to facilitate pflag parsing. But `--` stops pflag parsing, so
> really it should have been left alone.

### The Historical Thread

Trace the problem back through its history. Show how prior attempts shaped
the current one. Link to issues, PRs, and discussions.

> Annoyingly, I [knew] about this problem, but instead of fixing it at the
> source -- as this commit does -- I added a lower-level check that could
> then not be backported to release-20.2, where we are now seeing this
> problem.
>
> [knew]: https://github.com/cockroachdb/cockroach/issues/54444#issuecomment-707706553

> This was originally introduced in #33282 in response to a resource leak
> (goroutine buildup) under prolonged network partitions. However this type of
> testing never caught on and the meaningful part of these tests has been skipped
> for years at this point, with little hope for a comeback.

### The Technical Deep Dive

For substantial changes, structure the explanation clearly. Use **Background**
and **This PR** sections when it helps. Don't shy away from length when the
change warrants it -- but every sentence should earn its place.

> **Background**
>
> We would like to apply log entries at startup time, and so we are
> working towards making all code related to entry application
> stand-alone (and, as a nice side product, more unit testable).
>
> **This PR**
>
> This PR provides an implementation of `apply.Command` outside of
> `kvserver` in a way that does not lead to code duplication.

### The Honest Assessment

Be frank about limitations, past mistakes, and things you don't fully
understand. This builds trust with reviewers.

> I spent a couple of hours trying to deflake this, but whenever you fix
> one thing, another springs up. This test is not maintainable, and is
> highly complex.

> I'm not sure why I didn't introduce this much earlier, must have been
> a long bout of misguided purism.

> This seems unrelated to the test. We don't actually guarantee that a single
> node raft group can't transition through StateCandidate; clearly it's possible.

> I don't know why the KV Put in the drain step failed on a broken connection,
> but either way:

### The Pragmatic Tradeoff

When making an imperfect choice, acknowledge it and explain why it's the
right call anyway.

> It's not pretty, but pragmatic: it works and it'll be clear to anyone adding
> a histogram in the future how to proceed, even if they may wonder why things
> work in such a roundabout manner.

> I stopped short of updating the other tests entirely -- that would likely
> take me more time than I'm willing to additionally spend here -- but I
> left comments that should be actionable should any of these tests ever
> cause issues.

> This could all be refactored, but for now just fix the test and get on
> with it.

### The Reproduction Evidence

Include commands, numbers, and timing data that back up your claims.
Reviewers should be able to verify or reproduce what you're describing.

> I was able to reproduce the flake in a few minutes on my gceworker via
>
> ```
> ./dev test --count 10000 --stress ./pkg/kv/kvserver \
>     --filter TestLeaseQueueLeasePreferencePurgatoryError  -- \
>     --jobs 100 --local_resources=cpu=100 --local_resources=memory=HOST_RAM 2>&1
> ```
>
> This no longer reproduces as of this PR.

> Previously failed in <3 min on my gceworker. Now:
>
> > 41702 runs so far, 0 failures, over 25m50s

### The While-Here Discovery

When you stumble on something while working on something else, say so. It
adds credibility and explains why the change scope is what it is.

> Noticed while looking at the artifacts for an unrelated test failure:
>
> ```
> goroutine 686898 [chan send, 446 minutes]:
> ```

> Since I was here I couldn't help but also massage the output a bit.

> Saw this in a random heap profile during recent experiments.

### The Concise One-Liner

When the change is trivial, one sentence is enough. Don't pad.

> Avoid shadowing package name.

> Both callers now pass it in, which is cleaner.

> There is not a ton of incremental coverage here.

> This would fail.

> It was logging in the wrong place.

### The Footnote Trail

Use `[^1]` footnotes and `[name]: url` reference links to keep the main
text readable while providing depth for those who want it.

> Contrary to what I believed, merging profiles generally results in a
> larger file. Pick only the profiles from the first run of each test.
> Also, zero out the labels which are sometimes rather large (SQL query
> strings).
>
> This brings the generated proto down from 13MB to 1MB.

> The function's own comment stated that errors should be "logged and
> ignored", but two of the three error paths were propagated.

### The Wry Aside

Dry observations that show you see the absurdity without belaboring it.

> We would descend into madness similar to that experienced in the absence
> of the mechanism in the first place.

> This adds one sneaky little AUTH that was missed in #64840.

> Took me a bit to grok it, shouldn't be so hard for the next person.

> As far as I can tell, nobody's proactively fixing them, so we should not
> prompt engineers to report additional duplicates.

### The Clear Scope

Explicitly state what the commit does and does not do. Mention next steps
when relevant.

> This commit introduces the method signature only; it does not take dumps yet.

> Arg sniffing remains somewhat fragile, but at least now this particular
> case works like a charm.

> I don't feel too bad about it. I still think it is a priority to be able to
> "comfortably" create at least "simple" raft logs.

## Structural Patterns

Tobi often uses these structural elements:

- **Background / This PR / Next Steps** sections for substantial changes
- **Footnotes** (`[^1]`) for references that would interrupt the main narrative
- **Reference links** (`[name]: url`) for clean inline citations
- **Code blocks** with reproduction commands, error messages, or benchmark results
- **Markdown tables** when comparing before/after behavior

## Anti-Patterns

Don't do any of these:

- **Generic filler.** Don't write "This commit introduces..." or "The purpose
  of this change is to...". Tobi just says what the change does.
- **Unearned confidence.** Don't claim certainty about things you don't fully
  understand. Tobi says "I'm not sure" or "I don't know" when that's the truth.
- **Vague handwaving.** Don't say "improves performance" without numbers or
  "fixes a bug" without explaining the mechanism.
- **Missing links.** Tobi almost always links to the relevant issues, PRs, and
  prior art. If you're referencing prior work, link to it.
- **Padding short changes.** If the change is a one-liner rename, write a
  one-liner commit message.
- **Hiding the investigation.** If debugging was involved, share the journey.
  The narrative of how you found the bug is often more valuable than the fix.
