# Backlog

Open work items and pending design decisions, kept here (rather than only in
Claude's per-machine memory) so they survive across computers. Last synced
2026-10-29.

---

## Open backlog items

### Miscellaneous open items

- **#450 Soft buttons in the text color (found 2026-10-29 on /admin):**
  the unlayered rule `.btn.btn-soft { color: var(--color-base-content) }`
  in assets/css/app.css makes every soft button a pale tint with gray text,
  which looks disabled. Decide whether to drop it (DaisyUI's colored soft
  text; Latte yellow/green would need the `-strong` shades as on outline
  buttons) and review the ~7 `btn-soft` uses plus the `<.button>` default.

- **#449 Admin maintenance actions on GET routes (found 2026-10-29 while
  checking the /admin buttons):** /search/push_missing, reset_all,
  delete_orphans, migrate and /maintenance/catch_up_thumbnailed,
  clear_journal, exception_notification are `get` in router.ex, so a
  browser prefetch or reloading a visited URL can trigger them (reset_all
  and clear_journal destroy data). Make them POST/DELETE and pass `method:`
  to the LinkButtons on the dashboard (data-confirm works with either).

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

### Admin grid duplication (found 2026-10-29 during #432)

- **#441 IndexGrid / ModerationGrid near-duplicates:**
  lib/pan_web/admin/index_grid.ex and moderation_grid.ex share most of their
  markup; the toolbar button class string is copied ~16 times across both.
  Likewise grid_presenter.ex vs grid_presenter_with_details.ex and
  data_block.ex vs relations_block.ex (same striped-row classes), and
  admin/record_form.ex vs components/moderation/record_form.ex. Candidate:
  one toolbar-button component and shared row helpers.
