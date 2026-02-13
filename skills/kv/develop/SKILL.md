---
name: develop
description: Produce high-quality, reviewable, and maintainable software through a disciplined, unsupervised development workflow. Use when tasked with implementing a feature, fix, or improvement that should result in a polished chain of git commits.
---

Invoke this skill when given a development task to implement, i.e. anything that
should result in code changes, a chain of commits, and ultimately a pull request.

# CockroachDB KV Development Workflow

You are tasked with producing high-quality, reviewable, and maintainable
software. After an initial back-and-forth with the user, you will complete this
work entirely unsupervised and non-interactively in a timely manner.

The reviewer is a skilled senior engineer with a high bar for code quality and
readability. You will be measured by the quality of the resulting code.

## Task Management

You will create and manage your own TODO list which you expand and consume as
you go. You will be done when the functionality specified by the user has been
reached AND the result is elegant, follows best practices, passes tests, and
closely resembles code that could have been written by a Senior Engineer.

## Output: A Linear Commit History

Your output will be a fully formed linear and "non-circuitous" `git commit`
history. The requirements are:

1. **Each commit passes tests** and quality considerations independently.
2. **Self-contained logical commits** - each commit should represent one coherent
   change.
3. **Separation of mechanical and semantic changes** - keep refactors, renames,
   and moves separate from behavioral changes.
4. **Quality comments** - explain "why", not "what".
5. **Easy to grasp** - each commit individually and as part of the entire chain
   should be straightforward to review.

After the work is complete, present the entire "arc" of changes in a single
message to the user in chat, suitable for use as a GitHub Pull Request
description.

### Commit Message Format

Follow the CockroachDB convention: `<package>: <lowercase verb phrase>`. The
package prefix scopes the change; the remainder is a concise, lowercase,
verb-first description. Examples:

- `kvserver: add comment to writeSST`
- `kvserver: plumb Engines into prepareSnapApply`
- `kvserver: move snapshot ingestion to snapWriter`
- `sql: fix panic in distsql physical planner`

Individual commits don't need an Epic or Release note line. The PR description
(presented in chat) should include these. To suggest a suitable epic, run:

```
git log --author="$(git config user.email)" --no-merges --since="1 month ago" --grep="Epic: [^Nn]"
```

and list the top few most likely epics so the reviewer can pick the right one
without having to look it up elsewhere. If none seem applicable, or for the
release note, fall back to `Epic: TODO`

### Structuring the Commit Arc

The commit sequence should tell a clean story. Some techniques that make PRs
easy to review:

- **Start with groundwork.** Leading with documentation-only or
  comment-only commits that explain the existing code can orient the reviewer
  before any behavioral changes land. Adding or improving doc comments on the
  code you are about to change is a powerful way to "teach" the reviewer and
  establish shared context.
- **Prefer progressive encapsulation over big-bang refactoring.** When moving
  responsibilities into a new abstraction, do it incrementally across several
  commits (plumb the new type, implement the core logic, move ownership of
  subsidiary concerns one at a time) rather than all at once. Each step should
  be independently reviewable.
- **Use TODO breadcrumbs between commits.** It is fine to add a TODO in one
  commit that the next commit resolves. This guides the reviewer through the
  planned progression and signals that a loose end is intentional and temporary.
- **Fold review feedback into the originating commit.** When addressing reviewer
  comments, amend the commit that introduced the code in question rather than
  adding fixup commits on top. The final history should read as though the
  feedback was incorporated from the start.

## Iterative Refinement

Think deeply about each change and perform multiple rounds of improvements.

- **Don't be circuitous.** Plan ahead so the commit history reads as though you
  knew the right approach from the start.
- **Amend freely.** If a prior commit could be better, rewrite it rather than
  layering fixes on top.
- **Backtrack when needed.** Discard an approach that isn't working rather than
  papering over it. You are allowed to freely use `git reset`, `git amend`, etc,
  within the ancestry of the current HEAD that you've authored.

## Testing

You will determine which tests to run to convince yourself of correctness for
each individual commit. Be mindful of turnaround:

- **Time your tests.** Track how long each test run takes.
- **Balance coverage and speed.** Strike a sensible balance between thorough
  coverage and the duration of each test invocation.
- **Prefer `require`** if it is already used in other tests within the Go module.
- **Run the right scope.** Use targeted test runs (specific packages or test
  names) rather than running the entire suite when appropriate.

### Red/Green Testing

Whenever reasonably possible, functional changes should be accompanied by
changes in test behavior that prove the new behavior works. Follow a red/green
pattern across commits:

1. **First commit: document current behavior in a test.** Add (or adjust) a test
   that captures the *existing* behavior — even when that behavior is wrong.
   This commit's tests pass, establishing a baseline.
2. **Second commit: fix the code and update the test.** The behavioral fix lands
   together with the test update so the test now asserts the *correct* behavior.

For example, when fixing a regression, the first commit introduces a test that
"documents" the bug (the test passes because it expects the buggy output). The
second commit applies the fix and updates the test expectation to reflect the
corrected behavior. The reviewer can see exactly what changed and why.

This approach is not a hard rule — don't introduce contrived or throwaway tests
just to check a box. But when a natural test exists (or is easy to write), the
two-commit red/green pattern makes the change far easier to review and gives
confidence that the fix actually addresses the problem.

## Bazel Build Files

Bazel `BUILD.bazel` files are **auto-generated**. Never edit them by hand.
After adding, removing, or renaming Go files or changing dependencies, run:

```
./dev gen bazel
```

This regenerates all `BUILD.bazel` files. Commit the result together with the
source changes that triggered the regeneration.

## Go Conventions

- Use **camelCase** for identifiers: `HTTP`, not `Http`; `ID`, not `Id`.
- Follow the conventions already established in the surrounding code.
- The style of neighboring files and packages is a lower bar - try to be
  at least as good, but often aiming higher is appropriate.
- **Make new types redaction-safe from the start.** Any type that may appear
  in log messages, error strings, or user-facing output should implement
  redaction-safe formatting from day one — retrofitting it later is error-prone
  and easy to forget. For types with a `String()` method, see *String
  Formatting and Redaction* below. For error types, see *Error Types* below.
- **Minimize function inputs; prefer purity.** Functions and methods should
  accept the narrowest possible inputs rather than large structs or objects from
  which only a small piece is used. If a function only needs one field from a
  large type, pass that field directly. This makes dependencies explicit, keeps
  functions easier to test, and avoids coupling to unrelated concerns.

  Bad — accepts a full `*cobra.Command` only to check one flag:

  ```go
  func buildClusterCreateOpts(
      cmd *cobra.Command,
      numNodes int,
      createVMOpts vm.CreateOpts,
      providerOptsContainer vm.ProviderOptionsContainer,
  ) ([]*cloud.ClusterCreateOpts, error) {
      if !cmd.Flags().Changed("gce-machine-type") { ... }
      // cmd is never used again
  }
  ```

  Good — passes the single piece of information the function actually needs:

  ```go
  func buildClusterCreateOpts(
      gceMachineTypeChanged bool,
      numNodes int,
      createVMOpts vm.CreateOpts,
      providerOptsContainer vm.ProviderOptionsContainer,
  ) ([]*cloud.ClusterCreateOpts, error) {
      if !gceMachineTypeChanged { ... }
  }
  ```

## String Formatting and Redaction

When adding a `String()` method to a struct, always implement
`redact.SafeFormatter` first and then build `String()` on top of it. This
ensures log output is redaction-safe by default.

**Before implementing**, ask the user whether all fields in the struct are
considered safe (i.e. never contain PII or customer data). Numeric IDs, counts,
timestamps, and internal enums are typically safe. Strings derived from user
input, SQL statements, or key contents are typically unsafe. The answer
determines whether the `SafeFormat` implementation can use `w.Printf()` for
everything or needs to treat some fields as unsafe.

**Pattern:**

```go
import "github.com/cockroachdb/redact"

// SafeFormat implements the redact.SafeFormatter interface.
func (s *MyStruct) SafeFormat(w redact.SafePrinter, _ rune) {
    w.Printf("field1=%d, field2=%d", s.Field1, s.Field2)
}

// String implements the fmt.Stringer interface.
func (s *MyStruct) String() string {
    return redact.StringWithoutMarkers(s)
}
```

**Testing:** Add an `echotest` that pins the output. Use
`zerofields.NoZeroField` so new fields can't silently go unprinted, and
`t.Name()` for testdata paths. For a single case:

```go
func TestMyStructSafeFormat(t *testing.T) {
    defer leaktest.AfterTest(t)()

    s := MyStruct{Field1: 42, Field2: 7}
    require.NoError(t, zerofields.NoZeroField(s),
        "update test and SafeFormat for the new field")
    redacted := string(redact.Sprint(s))
    require.Equal(t, s.String(), redacted,
        "redacted and unredacted output should be identical (all fields are safe)")
    echotest.Require(t, redacted,
        datapathutils.TestDataPath(t, t.Name()))
}
```

Only use table-driven style if there are multiple meaningful cases. Inside
subtests, `t.Name()` resolves to `testdata/TestParent/subtest`:

```go
for _, tc := range testCases {
    t.Run(tc.name, func(t *testing.T) {
        require.NoError(t, zerofields.NoZeroField(tc.input),
            "update test and SafeFormat for the new field")
        redacted := string(redact.Sprint(tc.input))
        require.Equal(t, tc.input.String(), redacted,
            "redacted and unredacted output should be identical (all fields are safe)")
        echotest.Require(t, redacted,
            datapathutils.TestDataPath(t, t.Name()))
    })
}
```

If the struct contains unsafe fields (user-supplied strings, SQL, key contents),
use `w.Print()` for those and test redacted/unredacted output separately.

## Error Types

Before introducing a new error type, consider whether the `cockroachdb/errors`
library already provides what you need. It offers many flavors for enriching
errors — `errors.WithDetail`, `errors.WithHint`, `errors.Mark`,
`errors.WithSecondaryError`, `errors.WithAssertionFailure`, and more. Browse
existing usage in the codebase for examples; often, wrapping an existing error
with additional context is sufficient and avoids the ceremony of a full custom
type.

When a custom error type **is** warranted — because you need structured fields,
a marker interface (e.g. `PurgatoryError`), or `errors.As` matching — implement
the full error contract. A bare struct with only an `Error() string` method is
**not sufficient**. CockroachDB errors must be redactable, unwrappable, and
properly formatted.

**Required interfaces and pattern:**

```go
var _ errors.SafeFormatter = (*FooBarError)(nil)
var _ fmt.Formatter = (*FooBarError)(nil)
var _ errors.Wrapper = (*FooBarError)(nil)

// FooBarError indicates that a foo operation failed because bar was not
// in the expected state.
type FooBarError struct {
    FooID int64
    Cause error
}

// SafeFormatError implements errors.SafeFormatter.
func (e *FooBarError) SafeFormatError(p errors.Printer) error {
    p.Printf("foo %d failed due to bar", e.FooID)
    return e.Cause
}

// Format implements fmt.Formatter.
func (e *FooBarError) Format(s fmt.State, verb rune) { errors.FormatError(e, s, verb) }

// Error implements error.
func (e *FooBarError) Error() string { return fmt.Sprint(e) }

// Unwrap implements errors.Wrapper.
func (e *FooBarError) Unwrap() error { return e.Cause }
```

**Key patterns:**

- **`Error()` delegates to `fmt.Sprint(e)`** — this routes through the
  `Format` → `SafeFormatError` chain so the error message is always consistent
  whether printed directly or via `%v`/`%+v`. Never format the message
  independently in `Error()`.
- **`SafeFormatError` returns the cause** — this lets the `errors` package
  chain the cause into formatted output. Don't duplicate the cause's message
  in the `Printf` call.
- **Compile-time interface checks** — the `var _ ... = (*T)(nil)` lines at
  the top catch missing interface implementations at build time.
- **Pin the output with `echotest`.** Just as with `String()` methods (see
  *String Formatting and Redaction* above), use an `echotest` to pin the
  formatted error output so regressions are caught automatically.
- **Look at existing examples.** `replica_unavailable_error.go` in `kvpb` is
  a good reference for the full pattern including protobuf-encoded causes and
  encoder/decoder registration. Search for `SafeFormatError` in the codebase
  to find more.

## GitHub Integration

Use `gh` to interact with GitHub. In particular, when looking at PRs and issues,
also look at the comments, especially when they're related to code review on the
PR.
