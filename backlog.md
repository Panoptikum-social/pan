# Backlog

Open work items and pending design decisions, kept here (rather than only in
Claude's per-machine memory) so they survive across computers. Last synced
2026-08-29.

---

## Open backlog items

### Move qa/prod secrets to `config/runtime.exs`
There's no `config/runtime.exs` at all today — the full config chain
(`config.exs` → `qa.exs`/`prod.exs` → `qa.secret.exs`/`prod.secret.exs`) is
compile-time only, so secrets (DB password, `PanWeb.Endpoint` `secret_key_base`,
mailer creds) end up baked in plaintext inside the release/image itself. Standard
modern Phoenix (1.6+) generates `runtime.exs` by default; this app predates/diverges
from that.

**Fix when picked up:** add `config/runtime.exs`, move secret-bearing keys out of
`qa.secret.exs`/`prod.secret.exs` into `System.get_env/1` reads gated by
`config_env()`, update `docker-compose.yml` to pass them via `environment:` instead
of baking them into the build context, update `DOCKER.md` accordingly. Touches both
the QA Docker flow and the bare-metal prod deploy — test both.
