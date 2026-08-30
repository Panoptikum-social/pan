# Backlog

Open work items and pending design decisions, kept here (rather than only in
Claude's per-machine memory) so they survive across computers. Last synced
2026-08-29.

---

## Open backlog items

### Move qa/prod secrets to `config/runtime.exs` (dev done, qa/prod remain)
There's no `config/runtime.exs` at all today — the full config chain
(`config.exs` → `qa.exs`/`prod.exs` → `qa.secret.exs`/`prod.secret.exs`) is
compile-time only, so secrets (DB password, `PanWeb.Endpoint` `secret_key_base`,
mailer creds) end up baked in plaintext inside the release/image itself. Standard
modern Phoenix (1.6+) generates `runtime.exs` by default; this app predates/diverges
from that.

**Status (2026-08-30):** `config/runtime.exs` now exists (commit `a74aa6c0`,
"migrated dev to runtime.exs"). The **dev** environment is fully migrated —
`Pan.Repo`/`:bot`/`Pan.Mailer` are env-var driven with defaults matching the old
values, `config/dev.secret.exs` (previously symlinked from the private
`pan-config` sibling repo) is retired. Scope was deliberately widened to include
dev, not just qa/prod, so every dev machine gets the same convention without
needing `pan-config` cloned.

**Remaining fix when picked up:** in `config/runtime.exs`, add `config_env() ==
:qa` and `config_env() == :prod` branches; move secret-bearing keys out of
`qa.secret.exs`/`prod.secret.exs` into `System.get_env/1` reads (raising for
anything required and missing, unlike dev's fallback-to-default approach — these
are real deploys, not a local machine). Update `docker-compose.yml` to pass qa's
values via `environment:` instead of baking them into the build context, update
`DOCKER.md` accordingly. Touches both the QA Docker flow and the bare-metal prod
deploy (which reads its secrets from `pan-config/prod.secret.exs` on the prod
host today) — test both before considering this item closed.
