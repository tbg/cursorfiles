---
name: commit-voice-ibrahim
description: Give commit messages Ibrahim's voice — methodical, thorough, and anchored in evidence. Use when the user asks to write a commit message "like Ibrahim would" or in "Ibrahim's voice".
---

# Commit Voice — Ibrahim (iskettaneh)

Ibrahim writes commit messages that are thorough and methodical. He
walks the reader through the problem, the solution, and the evidence
— often pasting benchmark results, captured output, or before/after
comparisons directly into the body. His prose is clear and unhurried;
he numbers changes, explains mechanisms, and signals future work.

This skill doesn't override mechanical format requirements from other
skills (like `<package>: <verb phrase>` subjects or `Epic:` / `Release
note:` lines). It's about the prose in between.

## The Moves

### "This commit..." as Default Opener

Ibrahim's most common sentence starter. Almost every body begins with
"This commit adds/changes/fixes/introduces/reduces/removes...".

> This commit adds engine assertions to assert that Log engine only
> accesses log engine spans, and state engine only accesses state engine
> spans.

> This commit introduces parallel callback handling in the gossip
> package.

> This commit reduces the replica mutex contention in GetRangeInfo().

> This commit deflakes the test
> TestLossQuorumCauseLeaderlessWatcherToSignalUnavailable especially
> for epoch-based leases.

### "Before this commit, ..." → "This commit..."

Ibrahim's two-beat structure for changes that fix or replace behavior.
He uses "Before this commit" more often than "Previously" — both
pivot to "This commit".

> Before this commit, the go scheduler latency metric was publish once
> every 10 seconds, and it was based on 2.5 seconds worth of data. That
> meant that there was 75% blind spot in that metric. [...] This commit
> builds on the current interval at which we measure the scheduler
> latency (100ms), and keeps adding these 100ms measurements into a
> histogram that gets published (and cleared) every 10s.

> Before this commit, every sidetransport sending interval, we used to
> wake up up-to N goroutines to send the sidetransport messages where
> N=number of nodes. [...] This commit addresses that by adding a small
> pacing duration while we wake up the goroutines to send messages.

> Before this commit, we used to take the write lock when querying the
> StoreDetailMu.status(). [...] This commit attempts to take the read
> lock, and only upgrades it to a write lock if we end up needing to
> update the lastUnavailable timestamp.

"Previously" also works when "Before this commit" would be awkward:

> Previously, we used to start meta1 and meta2 in one range at
> bootstrap, and rely on load-based splitting to split them if needed.
> However, in some cases, load-based splitting doesn't work when it
> decides to split a point in meta1 (meta1 is not allowed to split).
> This commit changes that by starting meta1 and meta2 as two separate
> ranges at bootstrap.

### Numbered Lists for Multiple Changes

When a commit does more than one thing, Ibrahim numbers the changes.

> This commit does two things:
>
> 1) Runs decommission/drains tests with more verbosity using the
> vmodule settings.
>
> 2) Increases the time we wait for decommission to finish.

> Moreover, this commit does the following:
>
> 1) Removes the spanSetBatch.ScanInternal override that was panicking
> with "unimplemented" [...]
>
> 2) Implements spanSetBatch.NewBatchOnlyMVCCIterator with proper span
> checking by wrapping the returned iterator.
>
> 3) Fixes a bug in spanSetBatch.SyncWait that was incorrectly calling
> CommitNoSyncWait instead of SyncWait.

> Changes done by this commit:
>
> 1. Create a short path for the case where we are not the leader.
>
> 2. Create a short path for the case where QuotaPool is not enabled.
> [...]
>
> 3. Untangle the rest of the cases where the QuotaPool is enabled.

### "This opens/should open the door to..."

Ibrahim's signature phrase for signaling future work.

> This opens the door to using the taskPacer in more packages.

> This should open the door to refactoring
> updateProposalQuotaRaftMuLocked() to reduce the replica mutex.

> will open the door to adding engine assertions (both for State and
> Log) engines.

### "This will be useful/handy..."

For explaining why a change matters going forward.

> This will be useful when we add Engine assertions (not only eval
> batch assertions).

> This will become handy in the future when we use spanset assertions
> throughput the engine.

> These profiles could feed into PGO, also they can be useful to
> investigate the performance of a specific run.

### Benchmark Results

Ibrahim pastes benchstat or sysbench output for any performance-related
change. The data speaks for itself.

> Benchmark results:
> ```
> name                          old time/op    new time/op    delta
> EmptyRebalance/add-remove-12     2.85s ± 1%     0.03s ± 8%  -98.96%
> ```

> Sysbench-settings shows ~2% throughput increase:
>
> [full benchstat table]

### Captured Output as Evidence

Ibrahim pastes real output — descriptors, CLI output, log excerpts —
to show exactly what changed.

> In order to ensure that we get the descriptors correct, I started a
> cluster (when meta1 and meta2 were on the same range), and manually
> split them and captured the descriptors:
>
> ```
> [1] Meta Key: /Meta1/""
>     Range r1:
>       StartKey: /Min
>       EndKey:   /Meta2/""
> ```

> Output example when running:
>
> ```
> ./cockroach node drain 3 --insecure ...
> node is draining... remaining: 3
> ```

### "However, ..." for Complications

Ibrahim uses "However" to introduce the complication or exception
that motivates the change.

> However, in some cases, load-based splitting doesn't work when it
> decides to split a point in meta1.

> However, those places are currently explicitly using
> DisableForbiddenSpanAssertions() to disable the assertions.

> However, most uses of node vitality don't need that calculation to be
> made.

### "Moreover, ..." and "Also, ..."

Ibrahim uses these to add secondary changes or notes.

> Moreover, this commit makes this special span representation explicit
> by introducing a new type called `TrickySpan`.

> Also, this commit adds DisableWriterAssertions so that we have the
> functions for reader, writer, and readwriter.

> Also, I think the code needs some refactoring to separate the RTT
> recording from the clock offset updating.

### "Note that..." for Asides

> Note that the same recursive disabling was already happening in:
> DisableReadWriterAssertions and DisableReaderAssertions functions.

> Note that we recently increased it from 6 to 7, but this doesn't
> seem to have been enough.

> Note that the benchmark basically tests that updating a specific
> store detail doesn't block accessing other store details.

### Deflake Commits with Root Cause Theory

Ibrahim explains the mechanism of the flake, sometimes hedging with
"it seems" or "I think".

> it seems possible to me that the node 1 might have not heard about
> the new leader, and hence not return a speculative lease.

> the 30 seconds countdown start from the beginning of the test, before
> creating the test cluster and running it. A few failures happened
> because the nodes took a long time in the CI to actually become up and
> running.

> I couldn't find anything that indicates an actual bug. I think that it
> might have been just a general slowness in the environment.

### "I" for Personal Methodology

Ibrahim uses first person when describing what he did to investigate
or verify a change.

> I started a cluster (when meta1 and meta2 were on the same range),
> and manually split them and captured the descriptors.

> I couldn't find anything that indicates an actual bug.

> I think we should ignore the splits that happen in the first 2 minutes
> of the test.

### "We" for Team/Codebase Context

> We were mistakenly reading r.shMu.state.Lease.Replica.NodeID without
> holding neither the replica mutex nor raftMu.

> We have seen cases before where there was an issue with the pending
> callbacks metric.

> We disable the check in exactly 3 locations we know that we currently
> touch those keys.

### "Similar to what we did in..."

Ibrahim references prior work when the current commit follows a
pattern.

> Similar to what we did in #157153, this commit does the same but for
> read-only batches.

> This commit is heavily copied from PR: #119594.

## Anti-Patterns

Don't do any of these:

- **Using "This patch..." or "This adds..." without "commit".** Ibrahim
  says "This commit adds/fixes/removes...".
- **Using "Now, ..." to pivot.** Ibrahim pivots from "Before this
  commit" or "Previously" back to "This commit".
- **Leaving the body empty for substantial changes.** Ibrahim always
  explains, even for deflake commits.
- **Skipping evidence.** If there are benchmark results, captured
  output, or descriptors that show the change works, paste them.
- **Using "As well, ..." as a transition.** Ibrahim uses "Moreover, ..."
  or "Also, ...".
- **Being vague about mechanisms.** Ibrahim explains how things work,
  not just that they changed.
