---
name: commit-voice-angela
description: Give commit messages Angela's voice — direct, practical, and grounded in operational impact. Use when the user asks to write a commit message "like Angela would" or in "Angela's voice".
---

# Commit Voice — Angela (angeladietz)

Angela writes commit messages that are direct and practical. She explains what
the change does, why it matters operationally, and moves on. Her prose is plain
and concrete — she connects changes to real-world impact (production clusters,
oncall toil, customer issues) more than most.

This skill doesn't override mechanical format requirements from other skills
(like `<package>: <verb phrase>` subjects or `Epic:` / `Release note:` lines).
It's about the prose in between.

## The Moves

### "This adds/updates/fixes/removes..." as Opener

Angela's most common sentence starter. She leads with what the commit does,
stated plainly.

> This adds a roachtest to validate that secondary stores eventually get the
> same set of metrics as the primary store for a node.

> This updates the following admission control metrics to be reported in
> nanoseconds instead of microseconds.

> This fixes a bug where scale down validation would fail on clusters with
> unified architecture enabled.

> This removes the intrusion `ScaleKubeCluster` rpc and server handler. It is
> not used anywhere in our codebase so this deletion is safe.

### "Previously, ..." → "Now, ..."

For changes that fix or replace something, Angela sets up the old behavior with
"Previously, ..." and pivots with "Now, ..." — not "This commit" or "This
patch".

> Previously, admission metrics were lazily initialized the first time the
> system tries to update it. Now, the metrics are initialized for all
> priorities upon store startup.

> Previously, the datadriven asim tests expressed node capacity in
> nanoseconds/core which are difficult to read due to lots of zeros. Now, the
> node capacity is expressed in cores (float) which is much more readable and
> less prone to user error.

> Previously, console wouldn't issue a disk resize request to intrusion when it
> thinks nothing is changing. Now, when the force flag is set on the request and
> the disk fields in the dedicated hardware spec are also nonempty, console will
> trigger a disk resize job in intrusion anyways.

### "This is done by..." / "This is fixed by..." / "This is achieved by..."

Angela explains the mechanism of the fix concretely.

> This is done by adding a mmaSpanConfigIsUpToDate to the asim `replica`
> struct, similar to the mmaSpanConfigIsUpToDate field on the `Replica` type.

> This is achieved by introducing a call to
> `n.runtimeLoadMonitor.recordCPUUsage` prior to starting the asynchronous
> monitor.

> This is fixed by not overwriting the `additions` metadata in
> computeAndStoreRegionDiffs when it is already set.

> This is resolved by running the query against the system cluster instead of
> the application cluster.

### Operational Grounding

Angela connects changes to real production impact — specific clusters, customer
names, oncall scenarios, or datadog monitoring. This is her most distinctive
trait.

> Booking's `mvr` cluster has hit this many times, where they try to scale
> down drastically while they still have too much data on the cluster for the
> requested fewer nodes.

> We still have one cluster running this version.

> This will eventually be used to monitor durations of advanced cluster scaling
> operations in datadog.

> resulting in multiple hour long delays between jobs being persisted, and
> those jobs being run.

> This will allow oncallers to resolve failed cluster deletions without a prod
> deploy.

### Direct About Temporary Fixes

When a fix is a stopgap, Angela says so plainly and states when it should be
replaced.

> This is a temporary patch which disallows users from enabling cmek if their
> cockroach version is at least 25.2. This check will be removed once there is
> a crdb version patch to fix the bug.

> This is a temporary fix - we'll need a more robust solution eventually, but
> this is good enough for now.

> setting a cert ttl of 4 years will give us a year until we hit this bug
> again. This is a temporary solution until we implement CA cert rotation, or
> fix the bug in another way.

### "As well, ..."

A distinctive transition phrase for adding secondary changes.

> As well, the initial workload is also removed since it did not add any value
> to the test scenario.

> As well, a comment from the old allocators DiversityScore impl is copied
> over.

### Short Reverts

Angela's revert messages are one sentence explaining what broke.

> This reverts commit ... This commit broke azure cluster creation.

> This broke full cluster restores on all clusters, so we'll revert it for now
> to prevent it from being released.

### Concrete Examples

When a change improves readability or usability, Angela shows a before/after
example.

> For example, `node_cpu_rate_capacity=8000000000` is now expressed as
> `node_cpu_cores=8`.

### "we" for Team Decisions

Angela uses "we" when describing team or operational context, not "I".

> we want to keep trying to kick off the edit cluster while the cluster is
> locked.

> we might as well benchmark it as well.

> we should fail proactively before starting up the asynchronous node capacity
> provider.

## Anti-Patterns

Don't do any of these:

- **Using "This commit..." or "This patch..." as openers.** Angela leads with
  "This adds/updates/fixes/removes...".
- **Pivoting with "This commit..." after "Previously".** Angela uses "Now, ..."
  or "This changes/fixes/ensures...".
- **Being abstract about impact.** Angela grounds changes in operational
  reality — name the cluster, the customer, the oncall scenario.
- **Hiding that a fix is temporary.** If it's a stopgap, say so and say when
  it should be replaced.
- **Using first person singular.** Angela uses "we", not "I".
- **Over-explaining trivial changes.** A typo fix or config bump gets one
  sentence.
