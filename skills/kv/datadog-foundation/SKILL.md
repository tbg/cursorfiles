---
name: datadog-foundation
description: Foundation skill for interacting with Datadog via the pup CLI and Datadog MCP server. Use when investigating logs, metrics, traces, incidents, monitors, or any other Datadog-related task.
---

# Datadog Foundation Skill

This skill provides comprehensive guidance for interacting with Datadog using
two complementary tools: the **pup CLI** and the **Datadog MCP server**. It is
designed as a foundation that task-specific Datadog skills can build on.

## Prerequisites

### Pup CLI

Before using any pup commands, verify it is installed:

```bash
which pup
```

If pup is NOT installed, ask the user:

> "The pup CLI is not installed. It is required for most Datadog operations.
> Would you like me to install it from https://github.com/DataDog/pup ?"

If the user confirms, install via:

```bash
go install github.com/DataDog/pup@latest
```

If the user declines, skip all pup commands and inform the user that Datadog
operations requiring pup are unavailable.

### Pup CLI Authentication

Pup must be authenticated before use. Check status first:

```bash
pup auth status
```

If not authenticated, prefer OAuth2:

```bash
# OAuth2 (recommended) -- opens browser for approval
export DD_SITE="us5.datadoghq.com"
pup auth login

# Or set API keys as fallback
export DD_API_KEY="<key>"
export DD_APP_KEY="<key>"
export DD_SITE="us5.datadoghq.com"
```

The Datadog site is `us5.datadoghq.com`. Always set `DD_SITE` or pass
`--site=us5.datadoghq.com` when running pup commands.

OAuth2 tokens auto-refresh. If a command fails with 401/403, run
`pup auth refresh` or `pup auth login`.

### Datadog MCP Server

Before using MCP tools, check whether the Datadog MCP server is available by
attempting a lightweight MCP call (e.g., `search_datadog_metrics` with a simple
`name_filter`).

If the MCP server is NOT available or not configured, inform the user:

> "The Datadog MCP server is not installed. All operations will use the pup CLI
> instead."

Then use pup for ALL operations, including logs, metrics, and other domains
where MCP would normally be preferred. Do NOT attempt to install the MCP server.

If the MCP server IS available, follow the Tool Selection Guide below for
choosing between MCP and pup.

---

## Tool Selection Guide

### Core Principle

**Optimize for data completeness and accuracy.** Choose whichever tool returns
richer, more complete data for the task at hand.

### Logs and Metrics: Prefer MCP

For the primary use case of **investigating logs and metrics**, MCP tools
provide meaningfully better results:

**Logs:**
- `search_datadog_logs` -- supports `extra_fields` with wildcard discovery
  (e.g., `extra_fields: ['*']`) to reveal all custom attributes on matching
  logs. Also supports `use_log_patterns: true` to cluster similar messages.
  Pup has no equivalent for either capability.
- `analyze_datadog_logs` -- full SQL (GROUP BY, COUNT, DATE_TRUNC, typed custom
  columns). Far more powerful than `pup logs aggregate`.
- **IMPORTANT: Most logs are stored in the Flex tier.** Always set
  `storage_tier: "flex"` on MCP log queries and `--storage="flex"` on pup log
  commands. Queries against standard indexes alone will likely return 0 results.
  Note that SQL aggregation (`analyze_datadog_logs`) on the Flex tier can time
  out for large scans. When you only need an approximate count, prefer
  `search_datadog_logs` (which returns an estimated count in metadata cheaply)
  over `analyze_datadog_logs` with `SELECT count(*)`.
  Use `analyze_datadog_logs` on Flex only when you need grouping/bucketing and
  can narrow the filter enough to avoid timeouts.

**Metrics:**
- `get_datadog_metric` (timeseries) -- supports multiple queries in a single
  call, formula expressions (e.g., `anomalies(query0, "basic", 2)`,
  `query0 / query1`), and binned statistical summaries (min/max/avg per bucket).
- `get_datadog_metric` (metadata) -- returns tag discovery with values, related
  assets (dashboards, monitors, SLOs using the metric).
- `search_datadog_metrics` -- can filter by query activity, configuration
  status, and related asset usage.

### MCP-Only Capabilities (Pup Has No Equivalent)

- **Traces**: `search_datadog_traces`, `get_datadog_trace`
- **Service dependency graphs**: `search_datadog_service_dependencies`
- **Host SQL analytics**: `search_datadog_hosts` (SQL over host inventory)

### Pup for Everything Else

Use pup for:
- All **write operations** (create, update, delete)
- All domains **MCP does not cover**: monitors, dashboards, SLOs, incidents,
  security, synthetics, tags, cost/usage, audit logs, cases, error tracking,
  on-call, API/app keys, cloud integrations, users/orgs, notebooks, downtime,
  scorecards, service catalog, CI/CD, RUM apps

### Cross-Validation Policy

Do NOT routinely use both tools for the same query -- they hit the same Datadog
APIs, so the data is identical, and it doubles API calls and rate limit budget.

However, if results from the primary tool seem incomplete, unexpected, or
confidence is low, cross-validating with the alternative tool is acceptable.
This should be the exception, not the default.

---

## Pup CLI Reference

### Global Flags

All pup commands accept:

```
--config <path>    Config file (default: ~/.config/pup/config.yaml)
--site <site>      Datadog site (use us5.datadoghq.com)
--output <format>  json | yaml | table (default: json)
--verbose          Debug logging
--yes              Skip confirmation prompts
```

### Command Pattern

```bash
pup <domain> <action> [flags]
pup <domain> <subgroup> <action> [flags]
```

### Time Range Flags

Many commands accept `--from` and `--to`:

```
--from="1h"                     # relative: 1h, 30m, 7d
--from="2024-02-04T10:00:00Z"   # absolute ISO 8601
--from="1707048000"             # Unix timestamp
--to="now"                      # default
```

### Data & Observability

```bash
# Metrics
pup metrics list --filter="system.*"
pup metrics search --query="avg:system.cpu.user{*}" --from="1h"
pup metrics query --query="avg:system.cpu.user{*}" --from="1h" --to="now"
pup metrics get <metric-name>

# Logs (always include --storage="flex" -- most logs are in Flex tier)
pup logs search --query="status:error" --from="1h" --storage="flex"
pup logs search --query="service:api" --from="7d" --storage="flex"
pup logs list --query="@http.status_code:[400 TO 499]" --from="30m" --storage="flex"
pup logs aggregate --query="service:web" --from="1h" --storage="flex" --compute="count:*" --group-by="status"

# Events
pup events list --from="1h"
pup events search --query="source:nagios" --from="24h"
pup events get <event-id>

# RUM
pup rum apps list
pup rum apps get <app-id>
pup rum sessions search --query="@application.id:<id>" --from="1h"
pup rum metrics list
pup rum metrics get <metric-id>
pup rum retention-filters list
pup rum retention-filters get <filter-id>
```

### Monitoring & Alerting

```bash
# Monitors
pup monitors list --tag="env:production"
pup monitors get <monitor-id>
pup monitors search --query="<search-term>"
pup monitors delete <monitor-id> --yes

# Dashboards
pup dashboards list
pup dashboards get <dashboard-id>
pup dashboards url <dashboard-id>
pup dashboards delete <dashboard-id> --yes

# SLOs
pup slos list --tag="service:api"
pup slos get <slo-id>
pup slos create --name="API Availability" --type="metric" --target=99.9 --timeframe="30d"
pup slos update <slo-id> --target=99.95
pup slos delete <slo-id> --yes
pup slos corrections list <slo-id>
pup slos corrections create <slo-id> --start="<iso>" --end="<iso>" --category="deployment"

# Synthetics
pup synthetics tests list
pup synthetics tests get <test-id>
pup synthetics locations list

# Notebooks
pup notebooks list
pup notebooks get <notebook-id>
pup notebooks delete <notebook-id> --yes

# Downtime
pup downtime list
pup downtime get <downtime-id>
pup downtime cancel <downtime-id> --yes
```

### Infrastructure

```bash
# Hosts
pup infrastructure hosts list --filter="env:production"
pup infrastructure hosts get <hostname>

# Tags
pup tags list
pup tags get <hostname>
pup tags add <hostname> --tag="env:prod" --tag="team:backend"
pup tags update <hostname> --tag="env:staging"
pup tags delete <hostname> --yes
```

### Security & Compliance

```bash
# Security monitoring
pup security rules list
pup security rules get <rule-id>
pup security signals list --from="24h"
pup security findings search --query="@severity:critical"

# Static analysis
pup static-analysis custom-rulesets
pup static-analysis ast
pup static-analysis sca
pup static-analysis coverage

# Audit logs
pup audit-logs list --from="7d"
pup audit-logs search --query="@user.email:admin@example.com"

# Data governance
pup data-governance scanner-rules list
```

### Incident & Operations

```bash
# Incidents
pup incidents list --status="active"
pup incidents get <incident-id>
pup incidents create --title="High Error Rate" --severity="SEV-2" --customer-impacted=true
pup incidents update <incident-id> --status="resolved"
pup incidents attachments <incident-id>

# On-call teams
pup on-call teams list
pup on-call teams create --name="Backend On-Call"
pup on-call teams update <team-id> --name="New Name"
pup on-call teams delete <team-id> --yes

# Cases
pup cases search --query="status:open"
pup cases create --title="Investigate latency spike" --priority="P2"
pup cases assign <case-id> --user="user@example.com"
pup cases archive <case-id>
pup cases projects list

# Error tracking
pup error-tracking issues search --query="service:api"
pup error-tracking issues get <issue-id>

# Service catalog & scorecards
pup service-catalog list
pup service-catalog get <service-name>
pup scorecards list
pup scorecards get <scorecard-id>
```

### CI/CD & APM

```bash
# CI/CD
pup cicd pipelines list
pup cicd events list

# APM
pup apm services list
pup apm services stats <service-name>
pup apm services operations <service-name>
pup apm services resources <service-name>
pup apm entities list
pup apm dependencies list
pup apm flow-map
```

### Organization & Access

```bash
# Users
pup users list
pup users get <user-id>
pup users roles list

# Organizations
pup organizations get
pup organizations list

# API keys
pup api-keys list
pup api-keys get <key-id>
pup api-keys create --name="CI/CD Key"
pup api-keys delete <key-id> --yes

# App keys
pup app-keys list
pup app-keys get <key-id>
pup app-keys register --name="Workflow Key"
pup app-keys unregister <key-id>
```

### Cost & Usage

```bash
# Usage
pup usage summary
pup usage hourly

# Cost
pup cost projected
pup cost attribution
pup cost by-org
```

### Cloud & Integrations

```bash
# Cloud providers
pup cloud aws list
pup cloud gcp list
pup cloud azure list

# Integrations
pup integrations slack
pup integrations pagerduty
pup integrations webhooks

# Miscellaneous
pup misc ip-ranges
pup misc status
```

---

## MCP Server Reference

MCP tools are invoked as structured tool calls. Below is a concise reference
for each tool with its key parameters.

### Log Investigation

#### search_datadog_logs

Search raw logs or discover log patterns.

Key parameters:
- `query` (required): Datadog search syntax. Examples: `service:nginx status:error`,
  `@http.status_code:[400 TO 499]`, `env:production AND -version:beta`
- `from` / `to`: Time range. Default: `now-1h` / `now`. Supports ISO 8601,
  Unix ms, or relative (`now-1h`, `now-15m`, `now-1d`)
- `extra_fields`: List of extra attributes to include. Use `['*']` to discover
  all available custom attributes. Do not prefix with `@`.
- `use_log_patterns`: Set `true` to cluster similar messages instead of
  returning raw logs
- `storage_tier`: **Always set to `"flex"`**. Most logs are in Flex storage.
  Other options: `online-archives`, `cloudprem`.
- `max_tokens`: Control response size (default 5000)
- `sort`: `-timestamp` (default) or `timestamp`

#### analyze_datadog_logs

SQL analytics over logs. Use for counting, aggregation, time bucketing.

Key parameters:
- `sql_query` (required): SQL against virtual `logs` table. Default columns:
  `timestamp`, `host`, `service`, `env`, `version`, `status`, `message`
- `filter`: Datadog search syntax to pre-filter logs before SQL
- `extra_columns`: Extend the table schema with typed columns. Each entry needs
  `name` and `type` (string, int64, float64, bool, timestamp, json, etc.)
- `from` / `to`: Time range (default: `now-1h` / `now`)
- `storage_tier`: **Always set to `"flex"`**. Most logs are in Flex storage.
  Other option: `cloudprem`.

**Performance note:** SQL aggregation on Flex tier can time out for large scans
(millions of rows). Narrow the `filter` as much as possible. For simple counts,
prefer `search_datadog_logs` (returns approximate count in metadata cheaply).
Use `analyze_datadog_logs` on Flex when you need grouping/bucketing and can
scope the query tightly.

Common SQL patterns:
```sql
-- Count by status
SELECT status, count(*) FROM logs GROUP BY status

-- Error rate by service over time
SELECT DATE_TRUNC('hour', timestamp) as hour, service, count(*)
FROM logs WHERE status = 'error'
GROUP BY DATE_TRUNC('hour', timestamp), service

-- Top services by log volume
SELECT service, count(*) FROM logs GROUP BY service ORDER BY count(*) DESC
```

DDSQL notes: Every non-aggregated SELECT column must appear in GROUP BY. SELECT
aliases cannot be reused in WHERE/GROUP BY/HAVING -- repeat the full expression.

### Metric Investigation

#### get_datadog_metric (timeseries)

Query metric timeseries data.

Key parameters:
- `queries` (required): Array of Datadog metric query strings.
  Examples: `['avg:system.cpu.user{*}']`,
  `['avg:redis.info.latency_ms{*} by {host}']`,
  `['p99:request.duration{env:prod}']`
- `formulas`: Array of formula expressions referencing queries by index.
  Examples: `['anomalies(query0, "basic", 2)']`, `['query0 + query1']`,
  `['query0 / query1 * 100']`
- `from` / `to`: Time range (default: 1h ago / now). Supports ISO 8601, Unix
  timestamps, or relative (`now-1h`, `now-24h`)
- `raw_data`: `true` for CSV, `false` for binned stats (20 buckets with
  min/max/avg). Auto-selected if omitted.
- `interval`: Time interval in ms. Overridden if it would produce too many points.

#### get_datadog_metric (metadata)

Get metric metadata, tags, and related assets.

Key parameters:
- `metric_name` (required): e.g., `system.cpu.user`, `redis.info.latency_ms`
- `include_tag_values`: `true` to get tags grouped by key with all values
- `include_related_assets`: `true` to see dashboards/monitors/SLOs using this metric
- `scope_tags`: Array of tags to scope (e.g., `['env:prod']`)
- `tag_filter`: Substring match on tags (e.g., `prod`)

#### search_datadog_metrics

List and discover available metrics.

Key parameters:
- `name_filter`: Filter by name with wildcards (e.g., `system.*`, `rum.*`)
- `tag_filter`: Filter by tags (e.g., `service:redis AND host:prod-1`)
- `is_queried`: `true` to show only actively queried metrics
- `has_related_assets`: `true` to show only metrics used in dashboards/monitors/SLOs
- `from`: Lookback window (default 1h, max 30d)

### Traces (MCP Only)

#### search_datadog_traces

Search APM trace spans.

Key parameters:
- `query` (required): e.g., `service:nginx status:error`,
  `trace_id:7d5d747be160e280504c099d984bcfe0`,
  `@duration:>5000000` (nanoseconds)
- `from` / `to`: Time range (default: `now-1h` / `now`)
- `custom_attributes`: List of custom attributes to include. Supports wildcards.

#### get_datadog_trace

Get all spans within a specific trace.

Key parameters:
- `trace_id` (required): The trace ID
- `only_service_entry_spans`: `true` for condensed hierarchical view
- `expand_span_id`: Drill into a specific span's hidden children
- `include_path`: Filter to spans matching `key:value` and their ancestors/descendants
- `extra_fields`: Additional meta/metrics tags to include

### Infrastructure

#### search_datadog_hosts

SQL over host inventory. Virtual table: `hosts`.

Columns: `hostname`, `hostname_aliases` (text[]), `tags` (hstore, use
`tags->'key'`), `cloud_provider`, `resource_type`, `instance_type`, `os`,
`os_version`, `agent_version`, `memory_mib`, `cpu` (hstore), `kernel`
(hstore), `sources` (text[]), `modification_detected_at` (timestamp).

```sql
-- List all prod hosts
SELECT hostname, instance_type, os FROM hosts
WHERE tags->'env' = 'prod' LIMIT 100

-- Count hosts by cloud provider
SELECT cloud_provider, count(*) FROM hosts GROUP BY cloud_provider
```

### Service Dependencies (MCP Only)

#### search_datadog_service_dependencies

Key parameters:
- `service`: Find dependencies for this service
- `direction`: `upstream` (callers) or `downstream` (callees)
- `team`: Find services owned by a team (alternative to `service`)

### Monitors, Dashboards, Incidents, Events, Services

These MCP tools overlap with pup. Use pup by default; fall back to MCP only
if cross-validating.

- `search_datadog_monitors` -- `query` param, e.g., `status:alert env:prod`
- `search_datadog_dashboards` -- `query` param, e.g., `title:Redis`, `id:abc-123`
- `search_datadog_incidents` -- `query` param (default: `state:active`)
- `get_datadog_incident` -- `incident_id`, optionally `include_timeline`
- `search_datadog_events` -- `query` param, e.g., `source:nagios`
- `search_datadog_services` -- `query` param, e.g., `name:foo*`
- `search_datadog_notebooks` / `get_datadog_notebook`
- `search_datadog_rum` -- `query` param, e.g., `@type:error`

---

## Workflow Patterns

### Log Investigation

All log queries should use `storage_tier: "flex"` (MCP) or `--storage="flex"`
(pup). Most logs are stored in the Flex tier.

1. **Discover available fields**: Use MCP `search_datadog_logs` with
   `storage_tier: "flex"`, `extra_fields: ['*']`, and a small `max_tokens` to
   see what custom attributes exist on matching logs.

2. **Search raw logs**: Use MCP `search_datadog_logs` with `storage_tier: "flex"`
   and the relevant `extra_fields` now that you know what exists. The response
   metadata includes an approximate total count -- use this instead of SQL
   `count(*)` when only an estimate is needed.

3. **Analyze patterns**: If volume is high, set `use_log_patterns: true` to
   cluster similar messages and identify dominant patterns.

4. **Aggregate with SQL**: Use MCP `analyze_datadog_logs` with
   `storage_tier: "flex"` for grouping, time bucketing, or breakdown analysis.
   Keep the `filter` narrow to avoid Flex tier timeouts on large scans. Define
   `extra_columns` for any custom attributes you need in SQL.

5. **Cross-reference**: Use `pup monitors list --tag="service:<svc>"` to check
   if monitors exist for the affected service. Use `pup incidents list` to see
   if an incident is already open.

### Metric Investigation

1. **Discover metrics**: Use MCP `search_datadog_metrics` with `name_filter` to
   find relevant metrics.

2. **Understand a metric**: Use MCP `get_datadog_metric` (metadata) with
   `include_tag_values: true` and `include_related_assets: true` to see what
   tags are available and which dashboards/monitors use it.

3. **Query timeseries**: Use MCP `get_datadog_metric` (timeseries) with
   appropriate queries. Use `formulas` for derived metrics or anomaly detection.

4. **Correlate**: Query multiple metrics in a single call using the `queries`
   array and `formulas` to compute ratios or deltas.

### Incident Response

1. Check existing incidents: `pup incidents list --status="active"`
2. Search related logs: MCP `search_datadog_logs` with `storage_tier: "flex"` and service/error filters
3. Check monitors: `pup monitors list --tag="service:<svc>"`
4. Analyze error rates: MCP `analyze_datadog_logs` with `storage_tier: "flex"` and SQL aggregation
5. Check traces: MCP `search_datadog_traces` for slow/errored spans
6. Create incident if needed: `pup incidents create --title="..." --severity="SEV-2"`

### Monitor Management

1. List monitors: `pup monitors list --tag="env:prod"`
2. Get details: `pup monitors get <id>`
3. Search: `pup monitors search --query="<term>"`
4. Delete: `pup monitors delete <id> --yes`

### Security Audit

1. Recent signals: `pup security signals list --from="24h"`
2. Critical findings: `pup security findings search --query="@severity:critical"`
3. Review rules: `pup security rules list`
4. Audit logs: `pup audit-logs search --query="<filter>" --from="7d"`

### Service Health Check

1. Service catalog: `pup service-catalog get <service>`
2. Dependencies: MCP `search_datadog_service_dependencies` with
   `service: "<name>"`, `direction: "downstream"`
3. Recent traces: MCP `search_datadog_traces` with `query: "service:<name>"`
4. Metrics: MCP `get_datadog_metric` with relevant service metrics
5. SLOs: `pup slos list --tag="service:<name>"`

---

## Output Handling

### Pup Output

Pup defaults to JSON. Parse with `jq` when chaining:

```bash
# Extract monitor IDs
pup monitors list --tag="env:prod" | jq '.[].id'

# Get names of alerting monitors
pup monitors list | jq '[.[] | select(.overall_state == "Alert") | .name]'

# Count by type
pup monitors list | jq 'group_by(.type) | map({type: .[0].type, count: length})'
```

Use `--output=table` when presenting results to the user for readability.

### MCP Output

MCP tools return structured data directly into the agent context. No parsing
step is needed -- the agent can read and reason over the response immediately.

### Chaining MCP and Pup

Common pattern: use MCP for discovery/analysis, then pup for action.

Example -- find and resolve an issue:
1. MCP `analyze_datadog_logs` to identify the error pattern
2. MCP `search_datadog_traces` to find the affected trace
3. `pup incidents create` to open an incident
4. `pup monitors list` to check if alerting is configured

---

## Troubleshooting

### Pup Authentication Failures

```bash
# Check status
pup auth status

# Refresh token
pup auth refresh

# Re-authenticate
pup auth logout && pup auth login

# Validate API keys directly
curl -X GET "https://api.us5.datadoghq.com/api/v1/validate" \
  -H "DD-API-KEY: ${DD_API_KEY}" \
  -H "DD-APPLICATION-KEY: ${DD_APP_KEY}"
```

### Rate Limiting (429)

Both pup and MCP hit the same Datadog API rate limits. If you get 429 errors:
- Reduce query scope (narrower time range, more specific filters)
- Add delays between sequential pup commands
- Avoid running both tools for the same query

### Empty or Unexpected Results

- Verify `DD_SITE` is set to `us5.datadoghq.com`
- Check time range -- default is often only 1 hour
- **For logs, ensure you are querying the Flex tier** (`storage_tier: "flex"` or
  `--storage="flex"`). Most logs are stored there; standard indexes will often
  return 0 results.
- For metrics, verify the metric exists: `pup metrics list --filter="<name>"`
  or MCP `search_datadog_metrics` with `name_filter`

### Debug Mode

```bash
pup --verbose <command>
# or
export PUP_LOG_LEVEL=debug
```

This shows HTTP request details, API endpoints, auth method, and response
status codes.
