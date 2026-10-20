# Backlog

Open work items and pending design decisions, kept here (rather than only in
Claude's per-machine memory) so they survive across computers. Last synced
2026-10-20.

---

## Open backlog items

### Miscellaneous open items

- **Logger backend for the error mails (found 2026-10-18).** The error mails
  come from the custom backend `Logger.Backends.ExceptionNotification`,
  registered via `config :logger, backends: [...]` in `config/prod.exs`.
  That key has been deprecated since Elixir 1.15 (warning at startup) but
  still works in 1.20. Options: add `{:logger_backends, "~> 1.0"}` and call
  `LoggerBackends.add/1` in the application start, or rewrite it as an
  Erlang `:logger` handler. Also (found 2026-10-19): it has no
  `handle_event(:flush, state)` clause, so it crashes with a
  FunctionClauseError whenever Logger flushes, e.g. at the end of
  `bin/pan eval` and on every stop. Harmless for the mails, one-line fix.
- **Faster compiles (found 2026-10-18).** Elixir 1.20's compiler option
  `elixirc_options: [module_definition: :interpreted]` can cut compile
  times on machines with many cores; the `.beam` files stay the same.
  Worth a try, optional.
- **Category clean-up, second look (found 2026-10-19).** The user cleans up
  categories on prod with `/admin/categories/merge` (namesakes colored, empty
  ones deletable, podcast counts) and restores a prod backup to dev on
  2026-10-20. Then look at the result again: remaining namesake groups, same
  titles meaning different things under different parents, strays that grew
  back. The parser matches titles ignoring case and surrounding spaces since
  2026-10-19; no table remembers merges (by decision), so occasional
  re-merging is the plan.
- **npm audit advisories in the build tools (found 2026-10-19).** `braces`
  3.0.3 (high, via `@tailwindcss/cli` → `@parcel/watcher` → `micromatch`) and
  `postcss-selector-parser` 6.0.10 (moderate, via `@tailwindcss/typography`
  0.5.20). Both are denial of service on hostile input and run only at build
  time on our own templates and CSS, never in the browser. `npm audit fix
  --force` would downgrade typography to 0.5.4, so not that. Check again
  after the next `@tailwindcss/cli` / `@tailwindcss/typography` releases
  (`cd assets && npm audit`).
