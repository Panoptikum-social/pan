Implemented 2026-08-28: `podcast:person` is parsed at channel level (→ `engagements`)
and item level (→ `gigs`) in `lib/pan/parser/analyzer.ex`, persisted via
`lib/pan/parser/contributor.ex` with the real role (`role` defaults to "host",
`group` dropped on purpose). Re-parse cleanup of feed-derived roles works by
exclusion (`role not in [owner, managing_editor, author]`, d4998679).

**Backfill closed 2026-10-12 (#56 → #112, user: "we leave it"):**
- Channel level is covered by `Pan.Job.RefreshPodcastMetadata` (monthly, full
  metadata re-parse): 30,188 of 30,410 active podcasts refreshed since the tag
  went in; 309 podcasts carry real roles (host, co-host, guest, ...).
- Item level only reaches episodes imported after 2026-08-28 (181 podcasts with
  real-role gigs). Older episodes don't get their persons — accepted.
- Rejected: #113 targeted additive backfill of ~310 podcasts, #114 full backfill.
  Reason a naive backfill is dangerous: `Episode.update_from_feed_many/2` prunes
  episodes missing from the feed, cascading into user likes/comments; the monthly
  job uses `skip_episodes: true` for that reason.

Don't propose an episode-level backfill again unless the user brings it up.
