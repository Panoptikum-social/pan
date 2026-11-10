Verified 2026-08-27 how the podcast polling interval (`update_intervall`, hours) behaves.
I initially claimed it only ever grows and never resets on activity — that was **wrong**;
the user pushed back and was right to. Corrected understanding:

- [Pan.Updater.Podcast.set_next_update/2](../../lib/pan/updater/podcast.ex)
  runs first on every scheduled check and unconditionally adds +1h, capped at
  `@max_update_intervall_hours` (168h / 7 days).
- But [Pan.Parser.Episode.insert/2](../../lib/pan/parser/episode.ex#L55-L63)
  fires whenever a genuinely new episode is persisted (reached from both
  `Persistor.initial_import` and `Persistor.delta_import`, i.e. the normal periodic-update
  path too) and unconditionally resets `update_intervall` to **10** and `next_update` to
  now+10h — overwriting the earlier +1h bump from the same check, since it runs later in
  the same request and both are plain sequential `Repo.update/1` calls on the same row.
- Net effect: a podcast that keeps publishing stays pinned near 10h; one that goes quiet
  backs off 1h per empty check up to the 7-day cap. This matches the intent described in
  the comment at the top of `podcast.ex` — I'd wrongly read that comment as stale/inaccurate
  before finding the reset in `episode.ex`.
- `PanWeb.Podcast.cut_update_interval_in_half/1` is genuinely dead code (never called) —
  harmless leftover, not evidence of a missing mechanism.
- Two things still genuinely true, not bugs but headroom: `Pan.Job.ImportStalePodcasts`
  processes one overdue podcast at a time with no concurrency, so real check cadence is
  bounded by podcast count × per-check latency regardless of `update_intervall`; and
  `publication_frequency` (avg. days between episodes, already computed) is displayed but
  never fed back into scheduling, so a daily and a weekly show get the same flat 10h reset.

**Why:** avoid repeating the same wrong "interval never comes back down" claim; the actual
gap (if any) is scheduling granularity/throughput, not a missing reset. See also
project_feed_redirect_loop_hardening from the same investigation session.
**How to apply:** if asked about update scheduling again, check both
`lib/pan/updater/podcast.ex` (the +1h/cap logic) AND `lib/pan/parser/episode.ex` (the
reset-to-10 on new episode) together — the behavior only makes sense combining both.
