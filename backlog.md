# Backlog

Open work items and pending design decisions, kept here (rather than only in
Claude's per-machine memory) so they survive across computers. Last synced
2026-08-29.

---

## Open backlog items

### Investigate stale/inert env vars in the prod systemd unit
While migrating prod secrets to `config/runtime.exs` (see item above),
found the systemd unit sets `Environment=MIX_ENV=staging "PORT=8888"` —
both look inert for how this app actually runs today:

* `MIX_ENV=staging` — `config_env()` inside a compiled release reflects
  whatever `MIX_ENV` was set to at `mix release` **build** time, baked into
  the release; it is not re-read from the environment when the release is
  *started*. Since the running app clearly uses `config/prod.exs`'s config
  today, the release must have been built with `MIX_ENV=prod` — meaning
  this systemd-level `MIX_ENV=staging` has no effect and is presumably
  leftover/copy-pasted from an old template. Worth confirming and either
  removing it or renaming/understanding why "staging" is there at all (is
  there a separate staging concept this hints at, now dead?).
* `PORT=8888` — `config/prod.exs` hardcodes `http: [port: 8888]` directly;
  nothing in the app reads `System.get_env("PORT")` outside of
  `config/dev.exs`. So this line happens to match the real port by
  coincidence, not because it's actually wired up — if `prod.exs`'s
  hardcoded port ever changed without updating this line (or vice versa),
  they'd silently disagree and only the hardcoded value would matter.

**Fix when picked up:** confirm both findings against the real host (e.g.
check what `MIX_ENV` the release was actually built with, whether anything
else depends on the systemd `PORT` var), then either remove the dead lines
or make `config/prod.exs`'s port actually read from `$PORT` if that's the
intent — don't just delete without understanding why they were added in
the first place.
