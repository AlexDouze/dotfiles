---
name: bifrost-code-mode
description: Guide for writing Bifrost executeToolCode scripts in the Starlark sandbox. Use when writing or debugging Bifrost MCP Python/Starlark code, or when using executeToolCode, listToolFiles, readToolFile, or getToolDocs meta-tools.
---

# Bifrost Code Mode: Starlark Execution Guide

You are writing code for Bifrost's **Starlark sandbox** — a Python-like interpreter with strict limitations. Your primary goal is to **maximize work done inside the sandbox** and **minimize what escapes to LLM context**. Every raw tool response that leaks out costs tokens.

## Core philosophy

Treat each `executeToolCode` call like a database query: go in with a question, come back with a precise minimal answer — never raw data.

## Discovery workflow

`listToolFiles` → `readToolFile(fileName="servers/srv/tool.pyi")` → (optional) `getToolDocs(server="srv", tool="tool")` → `executeToolCode(code="...")`

Skip discovery if signatures are already in context. If a domain skill (e.g., grafana) documents a tool's confirmed response structure, **skip probing for that tool** — use the documented structure directly.

## Tool return types — probe every unknown tool

**`.pyi` stub annotations are unreliable.** A tool annotated `-> dict` may return a bare list or a plain string.

**Rule: probe each unknown tool with the smallest possible request before the real call.**

```python
def main():
    # Use minimal params: narrowest time range, smallest page size, tightest filter
    r = server.some_tool(param="value", limit=1)
    t = type(r)  # returns "string", "dict", "list", "int" — a plain string, not a type object

    if t == "string":
        # Cannot parse in Starlark (no regex, no json). Return truncated, read in LLM,
        # then hardcode the needed value in your next call.
        # A string often signals infrastructure error — read it before retrying.
        return {"type": "string", "preview": r[:300]}

    if t == "list":
        if len(r) == 0:
            return {"type": "list", "len": 0}  # empty — widen query or report no data
        first = r[0]
        return {"type": "list", "len": len(r), "first_keys": list(first.keys()) if type(first) == "dict" else str(first)[:100]}

    if t == "dict":
        sample = {}
        for k in list(r.keys())[:3]:
            v = r[k]
            sample[k] = list(v.keys()) if type(v) == "dict" else str(v)[:50]
        return {"type": "dict", "keys": list(r.keys()), "sample": sample}

    return {"type": t, "preview": str(r)[:300]}

result = main()
```

**Chaining unprobed tools in one script:** probe tool A inline, extract what you need, call tool B in the same script — no separate `executeToolCode` needed.

```python
def main():
    a_r = server.list_things(limit=1)
    a_items = a_r if type(a_r) == "list" else a_r.get("things", [])
    if a_items == None:
        a_items = []
    target_id = None
    for item in a_items:
        if item.get("type") == "wanted":
            target_id = item["id"]
            break
    if target_id == None:
        return "not found"
    b_r = server.query_thing(id=target_id, limit=1)
    return {"id": target_id, "b_type": type(b_r), "sample": str(b_r)[:200]}

result = main()
```

**Empty results:** may be valid data (empty dataset) or a too-narrow probe. Widen the query before reporting "no data". Always guard indexing: check `len(r) > 0` before `r[0]`.

**If the probe result already contains the answer, parse it directly — no second call needed.**

## Syntax rules — Starlark is NOT full Python

| Rule                          | Wrong                | Right                                     |
| ----------------------------- | -------------------- | ----------------------------------------- |
| Tool calls: keyword args only | `srv.tool("val", 2)` | `srv.tool(param="val", n=2)`              |
| Dict access                   | `r.key`              | `r["key"]`                                |
| Safe access                   | `r.key or default`   | `r.get("key", default)`                   |
| No imports                    | `import json`        | use `.get()`, slicing, direct access      |
| No try/except                 | `try: ...`           | check with `.get()` and `if val == None:` |
| No classes                    | `class Foo:`         | use dicts `{"k": "v"}`                    |
| No loops/if at top level      | `for x in y:` at top | wrap in `def main():`                     |
| No `while` loops anywhere     | `while cond:`        | use `for` with range or restructure       |
| No f-strings                  | `f"n={n}"`           | `"n=" + str(n)`                           |
| No multi-line strings         | `"""..."""`          | `"a" + "\n" + "b"`                        |
| No **kwargs / *args           | `fn(**d)`            | spell out each keyword arg                |
| `type()` returns a string     | `type(x).__name__`   | `type(x) == "dict"`                       |
| Return value                  | top-level `return x` | `result = main()` at end                  |

**No time module:** compute timestamps in the LLM (ISO 8601 strings), pass as string arguments.

**Type conversions:** `int("42")`, `float("3.14")`, `str(42)` work. `round()` does NOT — use `int(float(x))`.

## Output minimization — always post-process

Bifrost echoes the **full raw response** into context regardless of what Starlark returns.

```python
# BAD — returns everything raw
result = server.list_things()

# GOOD — extract only what matters
def main():
    r = server.list_things()
    items = r if type(r) == "list" else r.get("things", [])
    if items == None:
        items = []
    return [{"name": d["name"], "id": d["id"]} for d in items]
result = main()
```

**Rules:** Extract only needed fields. Filter before returning. Truncate strings: `str(r)[:300]`. Never `print()` raw responses.

**Large list trap:** Some tools return thousands of items — Bifrost echoes the full API response as a `[TOOL]` line even when your Starlark returns only `len(r)`. Always use the smallest `limit` param; prefer server-side aggregation queries (e.g., PromQL `count()`) over fetching large lists.

**Multi-tool accumulation:** Each tool call in one script adds its full response to stdout. If total stdout > ~2KB, Bifrost saves it to a file and the `Return value:` section is unreadable. Keep each tool call's response small with tight `limit` params. Splitting into separate `executeToolCode` calls does NOT reduce total echo tokens — reduce data per call instead.

## Batching and error recovery

Chain steps in one script when you know the structure — avoid multiple `executeToolCode` round-trips.

**Pagination:** Some tools return `{"hasMore": true}` — check for it and fetch the next page if needed.

**Error recovery:** On execution error, read the error carefully, identify the exact line, fix it, retry **once**. If it fails again, report the error to the user rather than looping.

## Error prevention

- Use `.get("key", default)` for absent fields — but if the key exists with a `null` value, `.get("key", [])` still returns `None`. Follow up with `if value == None: value = []`
- Check `if value == None:` before using a result that might be missing
- When a search/filter API returns 0 results unexpectedly: `query=` often uses prefix/keyword matching, not substring — fetch all items without a query and filter client-side instead
