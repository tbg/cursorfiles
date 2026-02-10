---
name: fix-ci
description: Diagnose and fix CI failures on a GitHub PR. Use when the user asks to look at failing checks, fix CI, or investigate test failures on a pull request.
---

# Fix CI Failures on a PR

Diagnose failing CI checks on a CockroachDB pull request, identify actionable
failures, apply fixes, and offer to push.

## When to Use

- User says "fix CI", "look at the failing checks", "CI is red", etc.
- User shares a PR URL or number with failing checks.

## Step 1: Ensure You're on the Right Branch

Before anything else, verify the local branch matches the PR.

```bash
git branch --show-current
git log --oneline -10
git status --short
```

If the working tree is dirty or you're on the wrong branch, fix that first.
The user may have rebased or amended since the CI run — confirm the local HEAD
matches what was pushed:

```bash
git log --oneline origin/<branch> | head -3
```

## Step 2: Identify Failing Checks

Use `gh pr checks` to get the list of failures:

```bash
gh pr checks <PR_NUMBER> 2>&1 | grep fail
```

This gives you check names, durations, and URLs.

## Step 3: Get the Actual Failure Details

**Do NOT stop at the check name.** The check name (e.g. `lint`, `unit_tests`,
`check_generated_code`) is just a category. You need the actual test or error
message.

**Don't stop at the first failure**. If you found a single failing test, this
does not mean there aren't others. Check somewhat exhaustively so that each
turnaround is worth it. That said, some "basic" failures preclude most of the
tests from actually running, so failing fast is okay in those situations.

### Approach A: GitHub Annotations (fastest)

The GitHub Actions summary page often has an "Annotations" section with the
key error messages. Fetch annotations for a specific job:

```bash
gh api "repos/cockroachdb/cockroach/check-runs/<JOB_ID>/annotations"
```

The job ID is the numeric ID in the check URL (the last path segment of the
job URL from `gh pr checks` output).

### Approach B: Job Logs

Logs are only available after the **entire workflow run** completes (not just the
individual job). Check with:

```bash
gh run view <RUN_ID> --job <JOB_ID> --log 2>&1 | grep -i "FAIL\|error\|panic" | head -30
```

If you get "run is still in progress", the logs aren't available yet. Use
annotations (Approach A) instead, or wait.

### Approach C: Web Page

If the user provides a GitHub Actions URL, the page typically shows a "failure
summary" section listing the actual failing tests/packages. Use `WebFetch` to
read it if needed. It has this format:

> https://github.com/cockroachdb/cockroach/actions/runs/RUNNUMBER?pr=PRNUMBER

This is sometimes the only place listing the actual packages and the failed tests within.

### Common CI Checks and What They Mean

| Check | What it runs | Common fix |
|-------|-------------|------------|
| `check_generated_code` | `./dev generate` then diffs | Run `./dev gen bazel` and/or `./dev generate go`, commit results |
| `lint` | `//pkg/testutils/lint:lint_test` | Fix lint errors; often cascades from `check_generated_code` |
| `unit_tests` | All unit tests | Fix the failing test |
| `acceptance` | Acceptance tests | Often cascades from build failures |
| `docker_image_amd64` | Docker build | Often cascades from build failures |
| `local_roachtest` | Local roachtests | Check specific test failure |
| `local_roachtest_fips` | FIPS roachtests | Check specific test failure |

### Cascading Failures

Many failures cascade from a single root cause. Prioritize:
1. `check_generated_code` — if this fails, `lint`, `acceptance`, and `docker`
   often fail too.
2. Build failures — if the build is broken, everything downstream fails.
3. Actual test failures — address these only after build/gen issues are resolved.

## Step 4: Reproduce and Fix Locally

For generated code issues:
```bash
./dev gen bazel           # regenerate BUILD.bazel files
./dev generate go         # regenerate Go code (stringer, protobuf, etc.)
git diff --stat           # check what changed
```

For test failures:
```bash
./dev test ./pkg/path/to/package -f TestName -v --timeout 120s
```

For lint failures — these are often resolved by fixing the root cause
(`check_generated_code` or a code issue). If the lint failure is specific,
check the lint test log for the exact linter and message.

## Step 5: Commit and Offer to Push

After applying fixes, commit them. Follow the project's commit conventions
(see `kv.develop` skill if applicable).

**Important: Do not push automatically.** Instead, tell the user what you
fixed and offer to push:

> I've committed a fix for [description]. Want me to push?

Only push if the user confirms, or if they previously asked you to push
automatically (e.g. "fix CI and push").

## Step 6: Monitor (if asked)

If the user asks you to watch CI after pushing:

```bash
gh pr checks <PR_NUMBER> --watch --fail-fast
```

This blocks until checks complete or one fails. Be aware this can take 20-30
minutes for CockroachDB CI. If the user asks you to poll infrequently, use
`sleep` between manual checks instead:

```bash
sleep 600  # 10 minutes
gh pr checks <PR_NUMBER> 2>&1 | grep -E "fail|pending"
```

## Tips

- `gh pr checks` output includes URLs — use the run ID and job ID from those
  URLs when fetching logs or annotations.
- Job logs via `gh run view --log` can be very large. Always pipe through
  `grep` or `tail` rather than reading the full output.
- If `./dev gen bazel` fails locally due to pre-existing issues on the branch,
  try rebasing onto a fresh master first.
- When committing generated files, be careful with `git add -A` — it can sweep
  in unrelated untracked files from `./dev generate go`. Always add specific
  files explicitly.
