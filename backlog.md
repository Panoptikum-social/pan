# Backlog

Open work items and pending design decisions, kept here (rather than only in
Claude's per-machine memory) so they survive across computers. Last synced
2026-10-31.

---

## Open backlog items

### Miscellaneous open items

- **Revisit the category merge (next days, from 2026-10-21).** The mapping
  table (1c6a0807, Mappings tab on /admin/categories/merge, 34 old Apple
  names seeded) went to prod 2026-10-21, with the stray merges there. Check
  whether old names still come back while the monthly metadata refresh runs
  through the podcasts (rotation until about 2026-11-21), and merge any new
  strays (sub before parent, so the mapping gets the name feeds use).

- **#496 Parser saves unknown language codes without a name (found
  2026-10-31).** `Pan.Parser.Language.get_or_insert/1` inserts every
  language code it doesn't know yet with a UUID as `name` and `"_ is
  missing"` as `emoji`; they show up as "_ is missing <uuid>" in "Languages
  I speak" on Update Profile. 34 such rows came in since 2026-09-01 and were
  named by hand on prod 2026-10-31 (console script). New ones will keep
  coming until the parser handles unknown codes differently; how is open.

- **#498 Stale `podcasts.subscriptions_count` (found 2026-10-31).** The
  Subscribe button shows the stored count, which is only recomputed on a
  subscribe toggle (`Podcast.update_subscriptions_count/1`). On dev, podcast
  104 showed 19 while it has 16 subscriptions; after one toggle it was right.
  Counts go stale when subscriptions disappear another way (e.g. user or
  podcast deletion, merges). Same question for the like and follow counts.

