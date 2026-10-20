# Backlog

Open work items and pending design decisions, kept here (rather than only in
Claude's per-machine memory) so they survive across computers. Last synced
2026-10-20.

---

## Open backlog items

### Miscellaneous open items

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
