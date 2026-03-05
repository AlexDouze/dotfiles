# Global Claude Code Instructions

## Environment

- This is a macOS system
- Use Mac-compatible versions of bash tools (e.g., BSD variants of sed, awk, grep, etc.)
- Prefer GNU coreutils syntax only when explicitly installed via Homebrew (e.g., gsed, gawk)

## Bifrost MCP

Bifrost is an MCP gateway that aggregates multiple MCP servers behind four meta-tools (listToolFiles, readToolFile, getToolDocs, executeToolCode). It uses Code Mode: discover tools on-demand, then write Starlark code to orchestrate them.

**MANDATORY: Before writing any `executeToolCode` code, you MUST invoke the `bifrost-code-mode` skill (via the Skill tool). This is a hard requirement — never skip it.**

**Documentation Lookup**: When needing to fetch external library or API documentation, use Context7 through Bifrost MCP (via `executeToolCode`). Do not rely solely on training knowledge for up-to-date docs.


## Code Intelligence

LSP is available for Go, Python, and TypeScript. Prefer LSP over Grep/Glob/Read for code navigation — it finds semantic matches (handles renames, aliases, shadowing) rather than text matches:

- `documentSymbol` / `workspaceSymbol` — find symbols in a file or across the codebase
- `goToDefinition` / `goToImplementation` — jump to source
- `findReferences` — all usages (replaces Grep for symbol searches)
- `hover` — type/signature info (replaces Read for quick lookups)
- `incomingCalls` / `outgoingCalls` — trace call hierarchies

Use Grep/Glob/Read only for text/pattern searches (comments, strings, config files) or languages without LSP support.

After writing or editing code, check LSP diagnostics and fix errors before proceeding.
