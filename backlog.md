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
  (#442, `:moderation_live_view`) done, public site open): replace `bg-white`,
  `text-gray-*`, `border-gray-*`, raw Bootflat colors with `bg-base-*`,
  `text-base-content(/70)`, `border-base-300`, theme colors.
- **#433 Entity colors as theme tokens:** podcast, episode, category,
  recommendation (+ `-content`) defined per theme, used through one class or
  component each (e.g. `btn-podcast`), so episode and podcast buttons stop
  differing.
- **#440 Switch to Tabler Icons** (decided 2026-10-29, before #438/#439,
  which depend on it): today 54 icon templates in
  lib/pan_web/templates/live/icon/ mix Heroicons (40) and Line Awesome (13,
  unmaintained). Tabler (MIT, ~5,900 icons, `currentColor`) covers category
  topics. Vendor the full outline set (~5,000 SVGs) into the repo, rendered
  by name, so the #439 admin can pick any icon; replace the 54 existing
  icons by Tabler equivalents. Also fixes the misspelled
  `clock-horoicons-outline.html.heex`.
- **#438 Entity buttons → colored links** (decided 2026-10-29): podcast,
  episode, category, persona, user components (built on `LinkButton`) render
  the entity's SVG icon in its entity color, then the title as a plain link
  (base text color, underline on hover). No emoji (can't be themed). Less
  space than buttons, which easily touch each other; avoids white-on-pastel
  contrast trouble. Do together with #433. Open: whether `large` header
  buttons keep a filled background.
- **#439 Distinct icon per category, then links there too:** every category
  (top level and subcategories) gets its own icon, so the category tree can
  also switch to colored links (replaces the chips in #434). Decided
  2026-10-29: icon stored in a column on `categories`, editable in admin;
  folder icon as fallback for strays without one; stable color per top-level
  category, subcategories inherit it (replaces the per-page rotation by
  `index_on_page`).
- **#434 Rainbow category tree stays** (until #439) as a deliberate exception: fixed
  rotation through the Catppuccin accents (exist in both flavours).
- **#435 Order:** admin converted
  and tested via `data-theme` toggle → moderation (done) → public site → re-enable automatic
  dark mode.
- **#436 Theme toggle:** done for admin and moderation (Latte /
  Mocha / System, assets/js/theme_toggle.js, localStorage `pan_theme`).
  Still open: the same for the public site, once it uses the themes.
- **#437 Remove the Bootflat palette** from `@theme` at the end, so leftover
  uses stop generating and show up by grep; also rework `.alert-*` and
  `.invalid-feedback` in app.css (use `-light`/`-dark` + `text-black`).
