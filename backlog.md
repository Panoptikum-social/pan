# Backlog

Open work items and pending design decisions, kept here (rather than only in
Claude's per-machine memory) so they survive across computers. Last synced
2026-11-05.

---

## Open backlog items

### Project #4: multilingual Panoptikum (started 2026-11-05)

Make Panoptikum multilingual: mostly the interface, but also some data,
e.g. category titles get translations.

Order (decided): 1. curations, 2. moderations, 3. frontend.

Decided 2026-11-05:

- #562 Languages: English and German. Maybe Italian, French and Spanish
  once everything is finished (far on the horizon).
- #563 Locale choice: user setting, then browser Accept-Language, then
  English. No URL prefix. Logged-out visitors get a switcher that stores
  the choice in a cookie. (The existing users_languages table is
  something else; check whether it can serve as a default.)
- #564 Groundwork is the first step of phase 1: locale plug + LiveView
  on_mount, gettext extract/merge workflow, core components translated
  (this changes buttons and labels on all pages).
  Done 2026-11-05 (dc660b57): PanWeb.Locale plug + on_mount, admin
  forced to English, `use Gettext` fixed in pan_web.ex, de locale with
  changeset errors and core components, `<html lang>` from the locale.
  User setting (users.locale, wins over cookie and browser) committed
  2026-11-05; not deployed yet (prod needs the migration).
- #573 Language switcher EN/DE in the sidebar, like the theme switcher
  (PanWeb.Component.LanguageToggle + assets/js/language_toggle.js). It
  POSTs to /locale (no "Are you sure?" for a language switch, OK by the
  user), which sets the cookie and, for logged-in users, the setting;
  then the page reloads. First version in dc660b57.
- #565 One gettext domain per phase (curation, moderation, ...), via
  dgettext.
- #566 Translated data (category titles) in a JSONB map column on the
  record, keyed by locale (e.g. `%{"de" => "..."}`).
- #567 Language names get translated too.
- #568 Emails go out in the recipient's language, not in the language of
  whoever triggered them.
- #570 Dates and numbers: translate month names only where pages show
  them; no ex_cldr unless really needed.
- #571 Gig/engagement roles get translated (gettext lookup, falling back
  to the stored value).
- #572 Curation grade labels get translated.
- #569 Search finds categories by their translated titles too
  (phase 3).
- Not translated: anything people write (podcast and episode data,
  community titles, curation texts, pads, comments), because the central
  element, the episode audio, stays in its language anyway.
- Not translated: the API stays English only.
- Not translated: admin stays English only (dropped as phase 4, the
  former "backend"). Admin pages must stay English even for German users,
  since they share the core components.

### Miscellaneous open items

- **Revisit the category merge (next days, from 2026-10-21).** The mapping
  table (1c6a0807, Mappings tab on /admin/categories/merge, 34 old Apple
  names seeded) went to prod 2026-10-21, with the stray merges there. Check
  whether old names still come back while the monthly metadata refresh runs
  through the podcasts (rotation until about 2026-11-21), and merge any new
  strays (sub before parent, so the mapping gets the name feeds use).
