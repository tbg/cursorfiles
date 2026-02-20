---
name: investigator
description: Investigate CockroachDB test failures, especially in the KV area. Use when the user asks to investigate a test failure, triage a flaky test, analyze a roachtest failure, or look into a CI test issue.
---

# CockroachDB Test Failure Investigator

Trigger the `investigate.yml` workflow on `cockroachdb/cockroach` to
autonomously investigate a test failure issue.

## Identify the Issue Number

The user's input may be:

- A GitHub issue URL (e.g. `https://github.com/cockroachdb/cockroach/issues/163542`)
- A bare issue number (e.g. `#163542` or `163542`)
- A description referencing a test name or SHA

If the user provided a URL or number, extract the issue number directly.

If the user only provided a test name, SHA, or error message, search for a
matching open issue:

```bash
gh issue list --repo cockroachdb/cockroach \
  --search "<test-name-or-error> label:C-test-failure sort:updated-desc" \
  --limit 5 --state open \
  --json number,title,url \
  | jq -r '.[] | "#\(.number) \(.title)\n  \(.url)"'
```

Present the candidates and ask the user to confirm which issue to investigate.

## Trigger the Workflow

Once you have the issue number, kick off the workflow:

```bash
gh workflow run investigate.yml \
  --repo cockroachdb/cockroach \
  -f issue_number=<ISSUE_NUMBER> \
  -f cheap=false
```

## Find the Workflow Run

After triggering, find the run and give the user its URL:

```bash
gh run list --repo cockroachdb/cockroach \
  --workflow investigate.yml \
  --limit 1 \
  --json databaseId,url,status,createdAt \
  | jq -r '.[] | "Run \(.databaseId): \(.status)\n\(.url)"'
```

Tell the user the workflow has been triggered and share the run link.

## Poll and Retrieve Findings

Offer to poll until the run completes. The run typically takes < 30 minutes.
If the user agrees, poll with `gh run watch`:

```bash
gh run watch <RUN_ID> --repo cockroachdb/cockroach --exit-status
```

This blocks until the run finishes. Alternatively, poll manually with sleeps
if you prefer more control:

```bash
gh run view <RUN_ID> --repo cockroachdb/cockroach --json status,conclusion \
  | jq -r '"\(.status) \(.conclusion)"'
```

Once the run has completed (regardless of success or failure), download the
findings artifact and display it:

```bash
gh run download <RUN_ID> --repo cockroachdb/cockroach \
  --name investigation-findings \
  --dir /tmp/kv-investigator/<ISSUE_NUMBER>
```

Then read `/tmp/kv-investigator/<ISSUE_NUMBER>/findings.md` and present the
full contents to the user. If the artifact is missing or empty, tell the user
the investigation did not produce findings and point them to the workflow run
URL to check the logs.
