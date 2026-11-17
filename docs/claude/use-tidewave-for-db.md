User rejected an ad-hoc `mix run --no-start -e` DB query with: "always use tidewave, if technically useful; if it's not available, prompt me".

**Why:** tidewave is the sanctioned way to inspect the dev app/DB; direct shell queries are not.

**How to apply:** Try tidewave first. If its tools aren't in the session, say so and ask the user, don't fall back to psql/mix run. Caveat (2026-09-21): MCP tools are loaded at session start; a server that failed to connect then (ConnectionRefused) stays unavailable even after the user restarts it, a new session is needed to pick it up. But if tidewave worked at session start and a call then fails with ECONNREFUSED (dev server restarted), just retry after checking localhost:4000 answers: it reconnected on the next call (2026-10-01).

**2026-11-17:** after the dev server restart that a dependency update needs, the session's tidewave MCP connection stayed broken; reconnecting via `/mcp` failed with "Dynamic Client Registration rejected (HTTP 404) … POST /register" (the client attempted OAuth, which tidewave doesn't offer; `/mcp` has no "Clear authentication"). The server itself answered a plain `initialize` POST fine. Fix: restart the Claude Code session.
