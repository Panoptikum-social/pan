# Backlog

Open work items and pending design decisions, kept here (rather than only in
Claude's per-machine memory) so they survive across computers. Last synced
2026-08-29.

---

## Open backlog items

### Move prod secrets to `config/runtime.exs` (dev + qa done, prod remains)
There's no `config/runtime.exs` at all today — the full config chain
(`config.exs` → `prod.exs` → `prod.secret.exs`) is compile-time only, so
secrets (DB password, `PanWeb.Endpoint` `secret_key_base`, mailer creds) end
up baked in plaintext inside the release itself. Standard modern Phoenix
(1.6+) generates `runtime.exs` by default; this app predates/diverges from
that.

**Status (2026-08-30):** `config/runtime.exs` now exists with `dev` and `qa`
branches, both done and user-confirmed working (commits `a74aa6c0`,
`f21bfec9`) — `config/dev.secret.exs` and `config/qa.secret.exs` are both
retired (the qa one deleted from the QA host after a full real test: build,
migrations, boot, all clean). Scope was deliberately widened to include dev
too, not just qa/prod, so every dev machine gets the same convention without
needing the private `pan-config` sibling repo cloned. qa's DB password +
`secret_key_base` now come from a single gitignored `.env` (see
`.env.example`), shared between the `app` and `db` docker-compose services
instead of duplicated by hand.

**Remaining fix when picked up:** add a `config_env() == :prod` branch to
`config/runtime.exs` mirroring qa's shape — `System.get_env/1` reads, raising
for anything required and missing. Prod is bare-metal (not docker-compose),
reading its secrets today from `pan-config/prod.secret.exs` (symlinked on the
prod host) — figure out the equivalent of qa's `.env` mechanism for that
deploy style (e.g. an env file sourced by whatever starts the release, or
systemd `EnvironmentFile=`), update the actual prod deploy process
accordingly, and test on the real prod host before considering this item
closed.
