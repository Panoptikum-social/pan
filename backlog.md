# Backlog

Open work items and pending design decisions, kept here (rather than only in
Claude's per-machine memory) so they survive across computers. Last synced
2026-10-20.

---

## Open backlog items

### Miscellaneous open items

- **Category clean-up towards Apple's current list (found 2026-10-19,
  direction decided 2026-10-20).** The second look on the 2026-10-19 prod
  backup: 30 categories grew back within 11 hours of the clean-up, because
  feeds use both Apple taxonomies (old: Sports & Recreation, Science &
  Medicine, Games & Hobbies, Government & Organizations, Health, News &
  Politics; current since 2019: Sports, Science, Leisure, Government,
  History, Health & Fitness, News) and merges had gone both ways. Current
  names grow back fast (Sports 94 podcasts in 14 h), old ones rarely.
  Goal: Apple's current list. `categories.apple` marks it (a677bfc8, "Update
  Apple flags" on the merge page fetches Apple's list from the iTunes genre
  service; Apple categories can't be deleted, merged away or moved).
  Route, done step by step by the user (search re-index: all podcasts and
  episodes of a renamed or merged category are re-pushed, measured on prod
  ~1.4 M episodes per hour, Sports & Recreation's 3.78 M take about 3 h;
  re-flagging goes through one queue, Pan.Search.ReflagQueue, 22d6b651):
  rename the old top level category to the Apple name in the admin grid
  (keeps id, URL, follows, subcategories), press "Update Apple flags" (the
  flag moves to the older, renamed one), then merge the young namesake into
  it, then the namesake subcategories below. Sports & Recreation → Sports,
  Science & Medicine → Science, Games & Hobbies → Leisure, Government &
  Organizations → Government. Deployed 2026-10-20; on prod the user did
  Sports, Science and Government the same day, History subcategories into
  top level History. Still open: Games & Hobbies → Leisure and the
  non-Apple subcategories per parent (old Apple ones and strays, suggested
  merges #305–#322 on 2026-10-20). The parser still re-creates names feeds
  use; no mapping table (by decision), so occasional strays remain.
- **npm audit advisories in the build tools (found 2026-10-19).** `braces`
  3.0.3 (high, via `@tailwindcss/cli` → `@parcel/watcher` → `micromatch`) and
  `postcss-selector-parser` 6.0.10 (moderate, via `@tailwindcss/typography`
  0.5.20). Both are denial of service on hostile input and run only at build
  time on our own templates and CSS, never in the browser. `npm audit fix
  --force` would downgrade typography to 0.5.4, so not that. Check again
  after the next `@tailwindcss/cli` / `@tailwindcss/typography` releases
  (`cd assets && npm audit`).
