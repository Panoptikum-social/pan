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

- **#451 Solid green "open – mark done" column (found 2026-10-29):** on
  /curator/communities/:id every open podcast's toggle is a filled
  `btn-success` (lib/pan_web/live/curation/community.ex), a solid green
  column against DESIGN.md. Candidate: `btn-outline btn-success` for open,
  `btn-outline` for done.

- **#449 Admin maintenance actions on GET routes (found 2026-10-29 while
  checking the /admin buttons):** /search/push_missing, reset_all,
  delete_orphans, migrate and /maintenance/catch_up_thumbnailed,
  clear_journal, exception_notification are `get` in router.ex, so a
  browser prefetch or reloading a visited URL can trigger them (reset_all
  and clear_journal destroy data). Make them POST/DELETE and pass `method:`
  to the LinkButtons on the dashboard (data-confirm works with either).

- **#446 Wrong icon after the counts on My Podcasts (found 2026-10-29
  during #444):** the category ranking in
  templates/user_frontend/my_podcasts.html.heex shows the `user` icon after
  each count, but the count is the number of my subscribed podcasts in that
  category. Check the recommendation/also-liked panels there too.

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

### Catppuccin themes (Latte light + Mocha dark), from 2026-10-29

A moderator reported the site almost unreadable on macOS in dark mode.
Likely cause: `@plugin "daisyui";` in assets/css/app.css enables DaisyUI's
stock `dark` theme with `--prefersdark`, so DaisyUI colors go dark while
~500 hard-coded classes (`bg-white`, `gray-*`, raw Bootflat colors like
`bg-lavender`) stay light. #430 (2026-10-29) turned the automatic dark theme
off (`themes: light --default`). #431 (e41d71eb): `latte` and `mocha` theme
blocks in app.css (all pairs AA; Latte light accents take dark text
#1e1e2e; base-300 = surface0, crust was too close to mantle), used only by
the admin layouts' `<main>` via data-theme. #432 done for the admin (shared
admin modules, LiveView admin pages, admin controller templates; links in
text color + underline, gray gradients replaced by solid base colors).
#432 (semantic classes everywhere) done 2026-10-29 (28bd5b7a); #436/#437
the same day: Latte/Mocha on every page, System (prefers-color-scheme) as
default, toggle in the sidebar, Bootflat palette and the old light theme
removed. Remaining items:

- **#445 Podlove subscribe button and web player in the theme:** style both
  to match Latte/Mocha and DESIGN.md (no solid color areas beyond the main
  action). Both are third-party widgets with their own configuration/theme
  (player: config theme tokens; subscribe button: its own color option), so
  check what they allow; check with real clicks/playback, not only renders.
