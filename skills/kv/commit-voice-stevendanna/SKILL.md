---
name: commit-voice-stevendanna
description: Give commit messages Steven's voice — thoughtful, first-person, and candid about uncertainty. Use when the user asks to write a commit message "like Steven would" or in "stevendanna's voice".
---

# Commit Voice — Steven (stevendanna)

Steven writes commit messages like he's explaining his reasoning to a colleague.
He thinks on paper — walking through what he observed, what he tried, what he's
not sure about, and why he landed where he did. The tone is first-person,
honest, and unhurried.

This skill doesn't override mechanical format requirements from other skills
(like `<package>: <verb phrase>` subjects or `Epic:` / `Release note:` lines).
It's about the prose in between.

## The Moves

### First Person by Default

Steven uses "I" freely. He doesn't hide behind "we" or passive voice when he's
describing his own reasoning or actions.

> I noticed this while making some other changes.

> I doubt this matters very much.

> I can't imagine it matters too much. But, I was considering adding another
> option field and noticed that if we make this change we can add one without
> increasing the size of the struct.

> I think I reversed this conditional when testing out the change and then
> failed to change it back.

> I was originally confused about the meaning of this flag resulting in a hung
> test run not timing out for hours.

> I find myself occasionally suspicious that some behavior is the result of a
> failed rangefeed client.

"We" appears when describing a team decision or a shared action, not as a
generic substitute for "I".

### "Here, ..."

Steven's signature transition from problem to solution. After explaining the
context, he pivots with "Here, ..." to introduce what this commit actually does.

> Here, I set the RaftTickInterval to MaxInt32 and also add subtests so that it
> is easier to know which subcase is failing if it fails again.

> Here, I simply wait for the raft state to list any leader.

> Here, we solve that by removing this UnregisterFromReplica callback
> completely.

> Here, we lower the write rate to keep the test more stable.

> Here, we track whether an explicit savepoint has been created and only flush
> those values required to rollback the earliest active savepoint.

> Here, we hopefully make the test less flaky by using a fakeResumer.

### Honest Uncertainty

Steven says when he doesn't know something. He shares theories, not conclusions,
when the evidence is incomplete.

> My suspicion is that under race, we are sometimes slow enough for the actual
> raft tick to come around and mark us as having a leader.

> My belief is that when the test was faster, the catch-up scans may have been
> completing before all of the relevant ranges had explicitly set span
> configuration.

> This is my best theory for what is happening in #146749 based on increased
> logging. It is difficult to be certain given the required ordering of events
> is hard to observe with locking.

> There may be more to understand here with respect to why this _particular_
> test is seeing this failure while others aren't.

> It's an open question about why this is failing more often recently.

> I don't know why this panic is here. If a reviewer happens to know, we can
> update this to a comment.

### Considered Alternatives

Steven explains what he didn't do and why, often in a separate paragraph. This
shows reviewers he thought about other approaches.

> According to the release note, an alternative here is to update our docker
> configuration on install.

> While we could call txn.SetBufferedWritesEnabled from the transactional ID
> generator itself, I opted to simply flush the buffer if we encounter an
> IncrementRequest.

> We may consider flushing the buffer instead to increase the set of
> transactions that can use this feature.

> I haven't plumbed this into virtual index populate because at the moment we
> only ever use virtual indexes for point lookups.

> This was pessimistic, since many transactions don't use explicit savepoints.

### Trailing Caveats

Steven often ends a commit message with a qualifying remark — something the
change doesn't solve, or an open question left for later.

> It doesn't solve whatever caused the original failure though, which doesn't
> seem to want to reproduce under stress yet.

> As far as I know we haven't seen an impact of this in any higher-level
> benchmarks.

> If we find ourselves touching this test again, we should consider scraping the
> whole thing.

> We should consider pushing this even further.

> One note is that this test is intended to be skipped under stress, but in CI
> it is still run under stress because of changes to the meaning of
> skip.UnderStress.

### "But, ..."

Steven starts sentences with "But," (comma included) when adding a
counterpoint. It's a small stylistic tic that gives his prose its conversational
rhythm.

> But, I plan to add another bool in a future commit and didn't want to push it
> over.

> But, I've added a timeout in case that isn't correct.

> But, we should be returning this error up the stack so that the user gets a
> clear error rather than a giant panic.

### Numbered Lists for Timelines and Consequences

When a bug or fix involves multiple steps or consequences, Steven reaches for
numbered lists.

> 1. Each restart attempt generates a new streamID.
> 2. Goroutine's A and B delete the streamID from the map before attempting to
>    restart it, and only attempt a restart if they found their ID.

> Not removing the processor from the replica in that case has two consequences:
>
> 1. We may hold onto memory related to the ScheduledProcessor struct,
> 2. The replica does extra work because of the rangefeed processor is set.

### Benchmark Results

When optimizing, Steven pastes benchstat output directly into the commit
message. No summary — the numbers speak for themselves.

### Deflake Commits with Theories

Steven's deflake commits are distinctive because they don't just say "bump
timeout." They explain the theory of why the test is flaking, what evidence
supports the theory, and how the fix addresses it. The fix is often described
as best-effort.

> This test depends on the closed timestamp not having advanced past the merge
> timestamp by the time of a post-merge write. The only thing making this true
> is that we set the target duration to a high value.
>
> We've seen this failing recently because that high value was not high enough.
> In this PR, we move the target duration from 10s to 30s.
>
> It's an open question about why this is failing more often recently.

### Brevity When Earned

For genuinely trivial changes, Steven keeps it short. But his threshold for
"trivial" is higher than most — he'll still write a sentence or two where others
would write nothing.

> We now only have 1 kind of processor. Here we update the metrics to reflect
> this reality.

> This only cared about measuring the elapsed time.

> The | operators precedence meant that the previous regex could match string
> such as OtherBytes:22.

## Anti-Patterns

Don't do any of these:

- **Dropping "I".** Steven's voice is first-person. Don't replace it with "we"
  or passive voice when he's describing his own reasoning.
- **Hiding uncertainty.** If the fix is speculative, say so. Don't write with
  false confidence.
- **Skipping the "Here, ..." pivot.** Context then solution, connected by
  "Here, ...".
- **Omitting alternatives.** If you considered another approach, mention it
  briefly.
- **Being terse for its own sake.** Steven is concise but not curt. He'd rather
  write one extra sentence of context than leave the reviewer guessing.
- **"This patch..." / "Previously, ..."** — Not Steven's framing. He jumps into
  the situation directly, often with what he observed or what the problem is.
