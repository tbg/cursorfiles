---
name: commit-voice-nicktrav
description: Give commit messages Nick's voice — precise, impersonal, and structured around the current state of the world. Use when the user asks to write a commit message "like Nick would" or in "Nick's voice".
---

# Commit Voice — Nick (nicktrav)

Nick writes commit messages that are precise and impersonal. His
signature move is opening with "Currently, ..." to describe the state
of the world, then stating the problem that follows, then the fix. He
never uses first person. His prose is technical but accessible — he
defines the problem space before diving into specifics, and separate
paragraphs handle separate concerns.

This skill doesn't override mechanical format requirements from other
skills (like `<package>: <verb phrase>` subjects or `Epic:` / `Release
note:` lines). It's about the prose in between.

## The Moves

### "Currently, ..." as Default Opener

Nick's most distinctive pattern. The vast majority of his commit bodies
begin by describing how things work right now, before introducing the
problem.

> Currently, `TestIngestValidation` ingests a file from the local
> filesystem. The ingested file uses a path that remains the same across
> test runs. This limits the ability of the test to run in parallel.

> Currently, the compression type for a table is known when the SST is
> new — i.e. flushed, compacted, ingested. However, when opening an
> existing DB, the compression types will show as "unknown".

> Currently, the metric for ingest-as-flushable counts the number of
> tables ingested, rather than the number of flushes that are handling
> ingested tables. This can be confusing to the operator.

> Currently, when computing the total size of a volume in
> `(defaultFS).GetDiskUsage`, `Bsize` is used to multiply the number
> of filesystem blocks to arrive at a total size.

> Currently, debugging a `BatchTimestampBeforeGCError` is difficult, as
> there information is lacking as to replica / range tried to touch
> underneath the GC threshold.

### Imperative Fix After Context

After the "Currently" setup and the problem statement, Nick states the
fix in imperative mood — often as its own paragraph.

> Alter the test to use `t.TempDir()` to ensure that the path is unique
> across test runs.

> Print the magic number bytes when encountering an invalid table magic
> number.

> Switch the existing metric to count the flushes handling ingested
> tables. Introduce a separate metric tracking the count of tables
> ingested as flushables.

> Only take the basename of the file, and mark this as safe.

> Mark this field as safe, by implementing `redact.SafeValue`, allowing
> it to be logged in full.

> Remove the metric.

### "This can result in..." / "This results in..."

Nick connects problems to their consequences explicitly.

> This can result in issues such as cockroachdb/cockroach#90150, where
> the denominator of a "percent available" calculation is computed using
> a larger value of `Bsize`, which results in the overall fraction
> falling below the allowable threshold for certain operations.

> This can tie up compaction slots.

> This results in the field being delimited with redaction markers in
> Cockroach log files.

### "In preparation for..." / "In anticipation of..."

Nick signals future work by grounding it in what's coming.

> In preparation for dropping support for table properties, add a
> format major version and associated migration to mark all pre-Pebblev1
> SSTables for compaction.

> In anticipation of the eventual wiring of the Pebble repo and our
> internal project management tool, apply the `T-storage` and
> `A-storage` labels to incoming issues.

> In preparation for 24.1.

### Code Examples and Console Output

Nick frequently includes Go code, console output, or formatted tool
output to illustrate the problem or demonstrate the change.

> This can be seen with the following example, run on macOS, inside of a
> Linux container:
>
> ```go
> func main() {
> 	path := os.Args[1]
> 	stat := unix.Statfs_t{}
> 	// ...
> }
> ```
>
> ```
> $ docker run --rm -it -v $(mktemp -d):/data test
> root@2d1ae8a4ce52:/# ./test /data/
> free:           535343923200
> total(Bsize):   256061686677504
> total(Frsize):  1000240963584
> ```

### Separate Paragraphs for Separate Concerns

Nick's longer commit messages have clear paragraph breaks — context in
one, problem in another, fix in a third, side effects or follow-ups in
a fourth.

> A manifest version uses reference counting to ensure that obsolete
> SSTables are only removed once it is safe to do so.
>
> In #1771, a new slice of `LevelMetadata` was added to support range
> keys. [...] Currently, when a version's ref count reaches zero, only
> the files present in the point key `LevelMetadata` slice have their
> ref counts decremented.
>
> Decrement the ref counts on files present in the range keys
> `LevelMetadata` slice, allowing the ref counts to be correctly zeroed.
>
> Add regression test to exercise the bug observed in
> cockroachdb/cockroach#90149.

### Precise Issue References

Nick uses specific verbs for issue references to communicate the
relationship:

- **"Fix #XXXX."** — the commit resolves the issue.
- **"Closes #XXXX."** — the commit closes the issue (non-bug).
- **"Touches #XXXX."** — the commit is related but doesn't close it.
- **"Informs #XXXX."** — the commit provides information toward the issue.

### Dash Lists for Enumeration

When listing items (metrics, conditions, settings), Nick uses dashes.

> Add metrics tracking the count of SSTables using various compression
> algorithms:
>
> - `storage.sstable.compression.snappy.count`
> - `storage.sstable.compression.zstd.count`
> - `storage.sstable.compression.unknown.count`
> - `storage.sstable.compression.none.count`

### Go Mod Bumps with Commit Lists

When bumping a dependency, Nick lists the upstream commits being picked
up in a code block.

> ```
> c24246ff db: fix redaction of ingest-as-flushable filenum
> abd6756c db: tweak ingest-as-flushable metrics
> 0a83de62 objstorage: add ctx to Create
> ```

### Self-Aware Brevity for Minor Changes

Nick acknowledges when a change is pedantic or aesthetic.

> Pedantic, aesthetic change to alphabetize the packages under
> `pkg/util`.

> Follow-on from #2236.

### "While it is _technically_ possible..."

Nick uses italicized qualifiers for nuance, acknowledging edge cases
without letting them block the change.

> While it is _technically_ possible that a table with containing
> exclusively range keys, but no range key sets _could_ be eligible for
> an elision-only compaction [...], the utility of such a compaction is
> minimal.

## Anti-Patterns

Don't do any of these:

- **Using "This commit..." or "This patch..." or "This adds...".**
  Nick describes the current state with "Currently, ..." and then
  states the fix in imperative mood.
- **Using first person.** Nick never writes "I" or "we". His prose is
  impersonal — the system and code are the subjects.
- **Using "Before this commit..." or "Previously, ...".** Nick uses
  "Currently, ..." to set up the status quo, not a retrospective
  framing.
- **Using numbered lists.** Nick uses dashes for enumeration, not
  numbers.
- **Skipping the "Currently" context.** Even for small fixes, Nick
  describes the state of the world before stating the change.
- **Being vague about consequences.** Nick connects problems to their
  observable effects with "This can result in..." or "This results
  in...".
