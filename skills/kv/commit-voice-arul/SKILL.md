---
name: commit-voice-arul
description: Give commit messages and PR descriptions a natural, human voice instead of stiff AI-generated prose. Use when the user asks to write a commit message "like Arul would" or in "Arul's voice".
---

# Commit Voice

When writing commit messages and PR descriptions, sound like the engineers on
this team actually sound. Not corporate, not formal, not like a changelog. The
examples below are all from real commits in this codebase.

This skill doesn't override mechanical format requirements from other skills
(like `<package>: <verb phrase>` subjects or `Epic:` / `Release note:` lines).
It's about the prose in between.

## The Moves

### The Aside

Drop in an observation that shows you actually looked at the code and have an
opinion about it.

> Previously, we would construct a ReplicaUnavailableError on the
> LeaderlessWatcher once (using an empty descriptor, which is rather hilarious)
> and never updated the error.

> This test wasn't doing as advertised on the tin after I broke some testing
> knobs in 02fa61b.

### The Honest Uncertainty

Say when you don't know something or when a fix is precautionary. Don't pretend
every change is the obviously correct one.

> I haven't been able to repro this. The test has failed twice in the last
> couple of days, so hopefully we'll be able to see why the rangefeed isn't
> ending up on n3 the next time this fails.

> I'm surprised we didn't see this before, but I think it's because the b-tree
> needs to be large enough for us to hit this. Either way, this is now fixed.

> I don't think this is a correctness issue today, and likely not one in the
> future even if this map is used for something other than epoch based leases
> ... I'm still pulling it up above the lease check we recently introduced out
> of an abundance of caution.

### The Shrug

When the change is simple, let brevity be the entire personality. Don't pad a
one-line change with three paragraphs of justification.

> Medium -> large.

> Conceptually clearer.

> The struct itself is private.

> Entirely mechanical, done using cursor.

### The Considered Tradeoff

Show that you thought about alternatives and chose deliberately. This is where
"For now, we do the simple thing" lives.

> I briefly considered other schemes where we didn't disable buffered writes
> completely once a transaction goes over budget -- either by only flushing the
> buffer partly or flushing the buffer in its entirety but allowing subsequent
> writes to be buffered as long as the transaction has budget. However, I
> decided against either of these ... For now, we do the simple thing.

> The least risky thing to do is to move this to 25.4 instead of a late stage
> backport, so let's do that.

### The Casual Closer

End with something that sounds like you're wrapping up a conversation, not
filing a report. This can be a short fragment or a full sentence that reframes
the change with a bit of insight.

> This work is entirely avoidable if there are no epoch based leases in the
> system ... So let's avoid it!

> so let's do that.

> Either way, this is now fixed.

> Turns out an AI can pattern-match "say I was surprised when describing a bug"
> way more effectively than it can interpret "sound like a teammate."

### Giving Credit

When someone else helped, say so naturally.

> H/t to @pav-kv for the analysis on this one.

### The Imperfect Acknowledgment

When something is ugly or not ideal, just say so. Don't dress it up.

> There's some ugliness here around requests that bypass AC entirely. They do
> so by setting the Source field; to ensure these are batched correctly, we
> bucket them separately.

### The Self-Deprecating Aside

Call out your own past mistakes. It's disarming and honest.

> While here, we also improve some terribly written (by me) commentary.

### The Signature Shorthand

Recurring phrases that signal familiarity with the codebase. Don't overuse,
but don't be afraid of them either.

> Burns down a TODO.

> While here, ...

> For now, this patch shall do.

### Playful Framing of Boring Work

Sometimes the change is mechanical and dull. A light touch makes it memorable.

> A little bit of test churn to keep things fresh.

### Brevity as Default

Most commits don't need more than a short paragraph. Say the *why* and the
interesting bits, then stop. Reviewers will read the diff — don't narrate it
back to them.

Match the weight of the message to the weight of the change. If the change is
straightforward, the message should be too. One paragraph on motivation and a
sentence on anything non-obvious is usually plenty.

### What Belongs in a Commit Message

The valuable stuff is what a reviewer *can't* see in the diff: tradeoffs
considered during development, known risks, escape hatches, and future
intentions. These should land casually, not as formal disclaimers. Think
"mentioned in passing" not "documented for the record."

> This could be chatty on clusters with many ranges, but the signal is
> worth it. If it turns out to be too noisy, we can always gate it behind
> some verbosity.

> I don't love the duplication here, but untangling it would mean
> refactoring half the file. For now, this patch shall do.

That captures a design decision that would otherwise be lost — and it reads
like something you'd say to a teammate, not something you'd write in a
design doc.

## Anti-Patterns

Don't do any of these:

- **"This commit introduces..."** — Just say what it does.
- **"The purpose of this change is to..."** — We can tell from the diff.
- **Narrating the diff.** Don't describe details the reviewer can see in the
  code. Say *why* the change exists and flag anything surprising about *how*.
  Let the diff speak for itself on the rest. For example, if you're adding
  logging, don't itemize what each log line contains, what fields are included,
  or what's already in the context tags — "we now log at the start and end of
  a GC cycle" is plenty for the commit message; the rest is the diff.
- **Numbering two things.** Prose paragraphs with "Firstly" / "Also" read
  better than a numbered list when there are only 2-3 items.
- **"Significantly improves" / "greatly enhances" / "robust solution"** — If
  the change is good, the description of what it does will speak for itself.
- **Starting every sentence with "This"** — Mix it up.
