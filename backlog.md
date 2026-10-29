# Backlog

Open work items and pending design decisions, kept here (rather than only in
Claude's per-machine memory) so they survive across computers. Last synced
2026-10-29.

---

## Open backlog items

### Miscellaneous open items

- **#444 Category ranking on My Podcasts without icons (found 2026-10-29
  during #432):** the "categories my podcasts are assigned to" panel gets
  `[count, id, title]` from a raw query in UserFrontendController.my_podcasts,
  so CategoryLink shows the folder icon and no color there. Add icon and the
  color (Category.color_map/0) to the query.

- **#443 Deprecated logger level (found 2026-10-29 during #440):** config/test.exs:39
  sets `config :logger, level: :warn`; Elixir 1.20 warns on every test
  run ("please use :warning instead").

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
Plan, in order:

- **#432 Semantic classes instead of fixed colors** (admin and moderation
  (#442, `:moderation_live_view`) done; on the public site sidebar, footer,
  entity links, panels and category tree done 2026-10-29 (#433, #438), the
  rest open): replace `bg-white`,
  `text-gray-*`, `border-gray-*`, raw Bootflat colors with `bg-base-*`,
  `text-base-content(/70)`, `border-base-300`, theme colors.
- **#439 Category icons and colors:** tree pages done 2026-10-29 (`icon` +
  `color` on categories, Pan.CategoryIcons proposals + "Fill missing icons"
  on /admin/categories/merge, CategoryLink on /categories and
  /categories/stats, `text-ctp-*` tokens: Latte shades darkened to 3:1).
  Open: press "Fill missing icons" on prod right after the deploy (else the
  public tree shows only folders); an icon/color picker in the admin
  (today plain text fields in the data browser).
- **#445 Podlove subscribe button and web player in the theme:** style both
  to match Latte/Mocha and DESIGN.md (no solid color areas beyond the main
  action). Both are third-party widgets with their own configuration/theme
  (player: config theme tokens; subscribe button: its own color option), so
  check what they allow; check with real clicks/playback, not only renders.
- **#435 Order:** admin converted
  and tested via `data-theme` toggle → moderation (done) → public site → re-enable automatic
  dark mode.
- **#436 Theme toggle:** done for admin and moderation (Latte /
  Mocha / System, assets/js/theme_toggle.js, localStorage `pan_theme`).
  Still open: the same for the public site, once it uses the themes.
- **#437 Remove the Bootflat palette** from `@theme` at the end, so leftover
  uses stop generating and show up by grep; also rework `.alert-*` and
  `.invalid-feedback` in app.css (use `-light`/`-dark` + `text-black`).
