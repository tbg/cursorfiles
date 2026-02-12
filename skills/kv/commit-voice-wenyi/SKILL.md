---
name: commit-voice-wenyi
description: Give commit messages and PR descriptions Wenyi's voice — methodical, clear, and forward-looking. Use when the user asks to write a commit message "like Wenyi would" or in "Wenyi's voice".
---

# Commit Voice — Wenyi

When writing commit messages and PR descriptions, sound like Wenyi actually
sounds. Methodical, clear, no wasted words but no shortcuts on context either.
The examples below are all from real commits in this codebase.

This skill doesn't override mechanical format requirements from other skills
(like `<package>: <verb phrase>` subjects or `Epic:` / `Release note:` lines).
It's about the prose in between.

## The Moves

### "This patch..."

Wenyi's most distinctive habit. The body of nearly every commit starts with
"This patch" followed by what it does. It's direct, unpretentious, and reads
like someone pointing at the diff and explaining it.

> This patch moves the comment for RangefeedUseBufferedSender to the line
> above it for aesthetic.

> This patch renames `r.disconnect` to `r.Disconnect`, making it a public
> method.

> This patch adds more debugging lines to cdcMixedVersionTester for
> cmvt.timestampsResolved.C.

> This patch skips TestCloudStorageSinkFastGzip under race due to an identified
> data race. This commit skips for now to unblock CI.

Don't avoid "This patch" — lean into it. It's the signature.

### "Previously, ..." → "This patch..."

For changes that fix or replace something, set up the old world with
"Previously, ..." and then pivot to "This patch..." for the new world. This
two-beat structure is the backbone of Wenyi's non-trivial commits.

> Previously, we bump the metrics in restartActiveRangefeed
> and again in handleRangefeedError. This patch addresses
> the issue of double counting metrics during rangefeed
> restarts.

> Previously, conditional check was used to find the maximum
> between sideTransportPropTime and raftTransportPropTime.
> This commit changes it to use the max builtin for better
> readability.

> Previously, errors were constructed and compared in pauseOrResumePolling
> solely to indicate that pausing cannot be stopped and period table history
> scan is necessary during pauseOrResumePolling. However, no actual errors
> were returned from pauseOrResumePolling. This error handling introduced
> unnecessary CPU overhead in this hot path, as observed during escalations
> and DRT scale testing. This patch improves performance by replacing
> error-based communication with a boolean check.

### "Future commits will..."

Wenyi often works in deliberate commit chains. She signals what's coming next
so reviewers know this is a stepping stone, not the whole story.

> While currently unused, future commits will refactor the unbuffered sender
> to use it.

> Note that BufferedSender is left unimplemented in this patch, and the setting
> is disabled everywhere. Using it will cause a panic. We will implement
> BufferedSender in a follow-up patch.

> In a future commit, we will introduce unbuffered registration, and this
> interface abstracts the implementation details of buffered and unbuffered
> registrations.

> We plan to revisit and refine this as we progress with the randomized
> testing framework.

### "Note that..."

Clarifying asides that preempt reviewer questions. These are factual, not
chatty — they head off confusion.

> Note that this patch should not change any behavior, and the main purpose
> is to make future commits cleaner.

> Note that this metric is only non-zero for unbuffered registrations.

> Note that all non-mux rangefeed tests have corresponding mux rangefeed
> tests, so we are not losing test coverage here.

> Note that we still need to avoid enabling the cluster setting for
> mixed-version roachtests to prevent it from being applied to versions that
> enforce this restriction.

### The Readability Rationale

When the change is purely about code clarity, say so directly. Don't
over-justify a rename or a restructure.

> for better readability.

> for better clarity.

> for aesthetic.

> to distinguish them.

### The Behavior Preservation Callout

Wenyi is explicit about refactoring commits not changing behavior. Reviewers
should know when a diff is safe to skim.

> Note that this patch should not change any behavior, and the main purpose
> is to make future commits cleaner.

> without changing any existing behaviour.

> This approach makes sense, as each rangefeed server stream should be a
> rangefeed event sink, capable of making thread-safe rangefeed event sends.

### The Honest Hedge

When something is incomplete or uncertain, acknowledge it plainly.

> We recognize there may be uncovered edge cases, but we've chosen a lenient
> approach as this is for testing purposes, and we want to avoid a potential
> time sink.

> It's unclear where the bug is yet. This patch disables this feature by
> default.

> While the benefits remain unclear, future commits will use this method to
> clean up metrics during multiple rangefeed disconnects.

### Brevity for Trivial Changes

When the change is small, the body is small. No padding.

> This patch renames stream with muxstream in node.MuxRangefeed to avoid
> confusion.

> This patch removes the unused field cancel from setRangeIDEventSink.

> This patch moves helper functions to registry_helpers_test.

### Structured Explanations for Bigger Changes

For more complex changes, Wenyi walks through the old design, why it was
problematic, what the new design does, and what's left. It reads like clear
technical writing, not a conversation.

> Previously, StreamMuxer was wrapped inside every rangefeed.PerRangeEventSink,
> where it was responsible for forwarding events to the underlying gRPC stream.
> However, with the introduction of a buffered stream sender in future commits,
> the responsibilities of StreamMuxer became unclear, as it needed to be able to
> forward events for both unbuffered and buffered senders. To simplify and
> clarify this functionality, this patch removes StreamMuxer and introduces a
> new struct, UnbufferedSender, which takes the responsibilities previously
> handled by StreamMuxer.

## Anti-Patterns

Don't do any of these:

- **Dropping "This patch..."** — It's the voice. Use it.
- **Getting conversational or quippy.** Wenyi's tone is clear and professional,
  not chatty. No dashes for asides, no "which is kinda funny", no shrugs.
- **Skipping the "Previously, ..." setup.** For non-trivial changes, reviewers
  need the context of what existed before.
- **Forgetting to signal future work.** If this is part of a chain, say so.
- **"Significantly improves" / "greatly enhances"** — Wenyi lets the benchmark
  numbers or the behavioral description speak for themselves.
- **Using first person singular.** Wenyi uses "we" or impersonal constructions,
  rarely "I".
