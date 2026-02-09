---
name: kv-develop
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

## Go Conventions

- Use **camelCase** for identifiers: `HTTP`, not `Http`; `ID`, not `Id`.
- Follow the conventions already established in the surrounding code.
- The style of neighboring files and packages is a lower bar - try to be
  at least as good, but often aiming higher is appropriate.

## GitHub Integration

Use `gh` to interact with GitHub. In particular, when looking at PRs and issues,
also look at the comments, especially when they're related to code review on the
PR.
