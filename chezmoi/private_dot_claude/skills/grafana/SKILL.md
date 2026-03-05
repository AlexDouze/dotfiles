---
name: grafana
description: Grafana MCP tool reference for Bifrost executeToolCode scripts against grafana_dev_central, grafana_it_central, and grafana_prod_central. Use when querying Grafana datasources (Prometheus, Loki, Tempo), exploring dashboards/alerts/incidents, or investigating issues across dev/it/prod environments. Documents confirmed response structures, exact parameter names, and gotchas. Also load the bifrost-code-mode skill for Starlark syntax rules.
---

# Grafana MCP — Bifrost Reference

Three servers: `grafana_dev_central`, `grafana_it_central`, `grafana_prod_central`.

**Also load:** `bifrost-code-mode` skill before writing any `executeToolCode` scripts.

**OnCall:** `list_oncall_*` tools return a plain string error when OnCall is not configured — do not retry, report to user.

**Common datasource UIDs** (consistent across all environments — skip `list_datasources` probe):
`loki`, `prometheus`, `thanos`, `alertmanager`, `tempo`
If a query returns 404/error, fall back to `list_datasources` to confirm the actual UID.

All `datasourceUid` parameters use **camelCase** — not `datasource_uid`.

---

## Simple tools — confirmed return types (skip probing)

| Tool                                                   | Returns                         | Notes                                                            |
| ------------------------------------------------------ | ------------------------------- | ---------------------------------------------------------------- |
| `list_loki_label_names(datasourceUid=)`                | bare `list[str]`                | iterate directly                                                 |
| `list_loki_label_values(datasourceUid=, label=)`       | bare `list[str]` OR error `str` | check `type(r) == "string"` first                                |
| `list_prometheus_label_names(datasourceUid=)`          | bare `list[str]`                | iterate directly                                                 |
| `list_prometheus_label_values(datasourceUid=, label=)` | bare `list[str]`                | iterate directly                                                 |
| `list_contact_points()`                                | bare `list[dict]`               | keys: uid, name, type, settings                                  |
| `list_alert_groups()`                                  | bare `list[dict]`               | keys: name, file, rules, interval                                |
| `search_folders()`                                     | bare `list[dict]`               | keys: uid, title, type, url                                      |
| `list_datasources(limit=50)`                           | `dict`                          | `r["datasources"]` → list; each item: uid, name, type, isDefault |

**`list_prometheus_metric_names`:** returns thousands of items → 400KB+ echo. **Never call this.** Use PromQL aggregation instead: `count(count by (__name__) ({__name__=~".+"}))`.

---

## Complex tools — confirmed structures

### `list_alert_rules`
```python
# params: limit=1000 (avoid pagination surprises)
# returns: {"groups": [...]} — each group has "rules": [{"health": "ok"|"error"|"nodata", "state": "Normal"|"Firing"|...}]
r = grafana_it_central.list_alert_rules(limit=1000)
groups = r.get("groups", None)
if groups == None:
    groups = []
```

### `search_dashboards`
```python
# params: limit=500, query= (prefix/keyword match ONLY — not substring, filter client-side)
# returns: {"dashboards": [...], "total": N, "hasMore": bool}
# each item: uid, title, folderTitle, url, type
r = grafana_it_central.search_dashboards(limit=500)
matches = [d for d in r["dashboards"] if "keyword" in d["title"].lower()]
```

### `list_incidents`
```python
# returns: {"incidentPreviews": [...] or null, "hasMore": bool}
# incidentPreviews can be null (not []) when empty — .get("key", []) returns None
r = grafana_it_central.list_incidents()
incidents = r.get("incidentPreviews", None)
if incidents == None:
    incidents = []
```

### `query_prometheus`
```python
# params:
#   expr (required): PromQL expression
#   queryType: "instant" or "range" — NEVER "query"
#   startTime (required): RFC3339 or relative ("now", "now-1h", "now-30m")
#   endTime: optional for instant; required for range
#   datasourceUid (required): camelCase
#   stepSeconds (required for range): interval in seconds
#
# returns: {"data": [{"metric": {...labels}, "value": [timestamp, "string_value"]}]}
# For range: "values": [[ts, "val"], ...] instead of "value"
# value is always a STRING — use int() or float() to convert
#
# Datasource scope:
#   "prometheus" = local central cluster only
#   "thanos" = ALL clusters (central + telco + admin) — use for cross-cluster queries
#
# Range query echo warning: 6h @ 5m step = 72 points per metric, all echoed.
# For summary stats, use instant queries with PromQL aggregation:
#   min_over_time(metric{...}[6h]), max_over_time, avg_over_time, last_over_time
# Use range queries ONLY when the full time series is needed.
r = grafana_it_central.query_prometheus(
    expr="up",
    queryType="instant",
    startTime="now",
    datasourceUid="prometheus"
)
series = r["data"]
results = [{"labels": s["metric"], "value": float(s["value"][1])} for s in series]
```

### `query_loki_logs`
```python
# params:
#   logql (required): LogQL — NOT "expr"
#   startRfc3339, endRfc3339: time bounds — NOT startTime/endTime
#   limit: max lines (max 100) — use smallest needed (echo grows with limit)
#   datasourceUid (required): camelCase
#   direction: "forward" or "backward" (default: backward = newest first)
#
# returns: {"data": [...]} or a plain error string
# Each entry: {"timestamp": "nanosecond_string", "line": "...", "labels": {...}}
# timestamps are nanosecond epoch strings, not human-readable
# "line" is plain text or full structured JSON (~500-800 chars) — always truncate
#
# LogQL filter expressions (reduce server-side, smaller echo):
#   {namespace="kps"} |= "error"          → literal include (case-sensitive)
#   {namespace="kps"} |~ "(?i)error"      → case-insensitive regex
#   {namespace="kps"} != "DEBUG"          → exclude
#   {app="svc", detected_level="error"}   → Loki auto-detected level (most reliable)
# Log level case varies by app — probe with limit=1 first to see actual format.
# "| json | line_format" is counterproductive — inflates labels, no benefit.

def main():
    r = grafana_it_central.query_loki_logs(
        logql="{namespace=\"kps\"} |= \"error\"",
        startRfc3339="<start>",
        endRfc3339="<end>",
        limit=20,
        datasourceUid="loki"
    )
    if type(r) == "string":
        return "Loki error: " + r[:200]
    logs = r.get("data", None)
    if logs == None:
        logs = []
    results = []
    for entry in logs:
        line = entry["line"]
        # Extract JSON fields via string search (no json/regex in Starlark)
        # Use unambiguous variable names — never l/li/l_start (collide with loop var)
        msg = line[:150]  # fallback: truncated raw line
        msg_idx = line.find("\"message\":\"")
        if msg_idx >= 0:
            msg_start = msg_idx + 11
            msg_end = line.find("\"", msg_start)
            if msg_end >= 0:
                msg = line[msg_start:msg_end]
        results.append({"ts": entry["timestamp"], "message": msg})
    return results

result = main()
```

**Service discovery (unknown label values):** Use regex stream selector instead of enumerating labels:
```python
# Try common labels: namespace, app, service_name
r = grafana_it_central.query_loki_logs(
    logql="{service_name=~\".*<keyword>.*\"}",
    startRfc3339="<recent>", endRfc3339="<end>",
    limit=1, datasourceUid="loki"
)
# If empty: try {app=~".*<keyword>.*"}, then {namespace=~".*<keyword>.*"}
# Once you get a result, read entry["labels"] for the exact values to use
```
Do NOT use `list_loki_label_values` for discovery — may return errors and is slow on large label sets.
