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

Prefer LSP over Grep/Read for code navigation — it's faster, precise, and avoids reading entire files:
- `workspaceSymbol` to find where something is defined
- `findReferences` to see all usages across the codebase
- `goToDefinition` / `goToImplementation` to jump to source
- `hover` for type info without reading the file

Use Grep only when LSP isn't available or for text/pattern searches (comments, strings, config).

After writing or editing code, check LSP diagnostics and fix errors before proceeding.
