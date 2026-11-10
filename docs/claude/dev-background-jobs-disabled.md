Commit 5fcbcf62 (2026-09-19) removed `Pan.Job.ImportStalePodcasts`, `Pan.Job.RefreshPodcastMetadata`, `Pan.Job.CacheMissingImages`, and `Pan.Job.PushMissingSearchIndex` from the `:children` list in config/dev.exs — only `Pan.Repo`, `PanWeb.Telemetry`, PubSub, and `PanWeb.Endpoint` start in dev now.

**Why:** not stated explicitly in the commit, but consistent with these jobs being long-running/heavy background workers (feed polling, metadata refresh) that are noisy or unwanted during normal local dev work.

**How to apply:** if a dev-environment session behaves as though a scheduled job never fires (e.g. testing project_import_stale_stall_sept2026-style behavior, or the project_podcast_update_job_backlog RefreshPodcastMetadata job), that's expected now — those jobs must be started manually or tested via `mix run`/IEx in dev, not by just booting the app.

**Since then (prod-only too, listed in config/prod.exs `:children`):** `Pan.Job.SendRetentionNotices` (2026-09-21, see [retention-notice-job](retention-notice-job.md)) and `Pan.Job.UpdatePodcastCounters` (2026-11-04, #498): runs `PanWeb.Podcast.update_all_counters/0` nightly at 02:22 Europe/Vienna (~90 s on prod; logs one info line per podcast plus a summary "all counters updated in N s"). Manual equivalent: the admin button "update all counters" (49 s on dev, 89 s on prod, not cut off by nginx).
