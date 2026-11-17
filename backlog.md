# Backlog

Open work items and pending design decisions, kept here (rather than only in
Claude's per-machine memory) so they survive across computers. Last synced
2026-11-05.

---

## Open backlog items

### Miscellaneous open items

- **Revisit the category merge (next days, from 2026-10-21).** The mapping
  table (1c6a0807, Mappings tab on /admin/categories/merge, 34 old Apple
  names seeded) went to prod 2026-10-21, with the stray merges there. Check
  whether old names still come back while the monthly metadata refresh runs
  through the podcasts (rotation until about 2026-11-21), and merge any new
  strays (sub before parent, so the mapping gets the name feeds use).

### Pending dependency updates (from 2026-11-17)

- **#640 npm audit: picomatch ReDoS** (GHSA-fc5q-39xc-vjpf, 4 high entries
  for one issue) via micromatch → `@parcel/watcher` → `@tailwindcss/cli`
  4.3.x, the Tailwind CLI's file watcher: build time only, never in the app
  or the browser. `cd assets && npm audit fix` says it can fix it; diff the
  built CSS/JS before and after. Prod deploy then needs `npm install`.
- **#642 timex 3.7.13 → 4.0.0.** Major version, blocked by
  `{:timex, "~> 3.7"}` in mix.exs: needs the constraint change and a check
  of what 4.0 breaks.
