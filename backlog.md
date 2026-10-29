# Backlog

Open work items and pending design decisions, kept here (rather than only in
Claude's per-machine memory) so they survive across computers. Last synced
2026-10-29.

---

## Open backlog items

### Miscellaneous open items

- **Revisit the category merge (next days, from 2026-10-21).** The mapping
  table (1c6a0807, Mappings tab on /admin/categories/merge, 34 old Apple
  names seeded) went to prod 2026-10-21, with the stray merges there. Check
  whether old names still come back while the monthly metadata refresh runs
  through the podcasts (rotation until about 2026-11-21), and merge any new
  strays (sub before parent, so the mapping gets the name feeds use).

- **npm audit advisories in the build tools (found 2026-10-19).** `braces`
  3.0.3 (high, via `@tailwindcss/cli` → `@parcel/watcher` → `micromatch`) and
  `postcss-selector-parser` 6.0.10 (moderate, via `@tailwindcss/typography`
  0.5.20). Both are denial of service on hostile input and run only at build
  time on our own templates and CSS, never in the browser. `npm audit fix
  --force` would downgrade typography to 0.5.4, so not that. Check again
  after the next `@tailwindcss/cli` / `@tailwindcss/typography` releases
  (`cd assets && npm audit`).
