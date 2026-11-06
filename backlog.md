# Backlog

Open work items and pending design decisions, kept here (rather than only in
Claude's per-machine memory) so they survive across computers. Last synced
2026-11-05.

---

## Open backlog items

### Project #4: multilingual Panoptikum (started 2026-11-05)

English and German; curations, moderations and frontend are done and
deployed (decisions and code map in Claude's memory, project_multilingual).
Open:

- #600 German screenshots for the German manuals: 51 of 53 done
  2026-11-06 (qed version saved, not published). Missing: the two shots
  taken on prod, API errors (manual-mod-api-errors.png, names blurred) and
  curators page (manual-mod-curators.png); the user takes them in German,
  Claude blurs/crops and imports them as `...-de.png` (#609).
- Untranslated or odd spots in the German UI, found while taking the #600
  screenshots (user decides):
  - #611 "more ..." in the start page box headers.
  - #612 Category names still English: International subcategories
    (Brazilian, Canadian, Dutch, French, German, Italian, Japanese),
    Digital Culture, Management & Marketing, College & High School.
  - #613 Roles on the podcast page stay English (Owner, Author,
    Contributor, Managing editor); the episode page translates them.
  - #614 "Explizit: false" on the podcast page (boolean not translated).
  - #615 Markdown editor placeholder "Start typing..." (persona edit, long
    description).
  - #617 Data tables: column headers in the moderation tables English
    (Title, Last Build Date, Blocked, 0 first, Search →); the persona
    search on /personas English throughout (Show, Records, Search mode,
    starts with).
  - #618 Feed check messages English (they come from check_my_feed).
  - #619 My Data shows raw values: true, de, 2026-11-06T09:17:26.
  - #620 Language list: "Assyrian" untranslated, "Katalanisch" twice.
  - #621 Moderator Edit podcast form: raw English field names (Update
    intervall, Title, Image url, Explicit, Retired, ...).
- #616 Podlove player sometimes loads too narrow (313 px instead of the
  column width) until the window is resized; seen in headless Chrome in
  both languages, check in a real browser.
- #562 Maybe Italian, French and Spanish once everything is finished (far
  on the horizon).

### Miscellaneous open items

- **Revisit the category merge (next days, from 2026-10-21).** The mapping
  table (1c6a0807, Mappings tab on /admin/categories/merge, 34 old Apple
  names seeded) went to prod 2026-10-21, with the stray merges there. Check
  whether old names still come back while the monthly metadata refresh runs
  through the podcasts (rotation until about 2026-11-21), and merge any new
  strays (sub before parent, so the mapping gets the name feeds use).
