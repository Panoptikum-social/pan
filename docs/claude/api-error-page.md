wisspod.de (community 1 "Wissenschaftspodcasts.de", category 106) polls the API hourly at ~:15. Their non-technical user sees errors without podcast names; goal: a moderator page showing the errors of their last run.

**Findings (2026-10-28, from journal + nginx):**
- #399 endpoints: `GET /jsonapi/podcasts/:id/?page[size]=1000` and `GET /jsonapi/pan/podcasts/:id/trigger_episode_update`.
- Deleted podcasts 53009, 52939, 200, 54 → 404 on both; all four were merges (see #406).
- 504 "Timeout when trying to download feed" for feed failures that aren't timeouts (403/404/500/503, not an rss feed): 51810, 185, 46997, 52940 every run; 638, 52726, 52595 occasionally.
- #403 manual `trigger_episode_update` does NOT write last_error_message/last_error_occured (only the background updater does) → page must record failed requests itself (option B: own table), not read podcast fields.
- #404 trigger_episode_update 404 returns the 23 KB HTML error page (Repo.get! raise) instead of JSON.
- #405 504 status misleading (open, API change = user's call).
- Journal: `journalctl -t pan` logs `GET path` + `Sent NNN` per request at :info; nginx access.log has status + IP.

**Decisions:**
- Journal not used; record failed requests in our own table (B).
- #400 filter by community (podcast in the community's category), not by API user.
- 404 message: "Podcast with Panoptikum ID 54 no longer exists." Unknown podcasts shown on the community pages (option a, assumed from the user's wording — confirm if unsure).
- #401 only community moderators look at it; admins seeing it too is fine.

- #402 page shows the last 24 hours grouped by podcast (error, count, last time).

- Rows kept 7 days, pruned on every insert (not a daily job).
- #405 option 1: keep status 504, title "Feed download failed", real cause in detail (no status change, clients unaffected).

**Built 2026-10-28 (0121d778):** api_request_errors table (no FK), PanWeb.ApiRequestError (record/5, last_day_by_podcast/1), before_send plug in Api.PodcastController for :show + :trigger_episode_update reading conn.private[:api_error] set by Helpers.send_error, JSON 404 "no longer exists" (also trigger_update), page PanWeb.Live.Moderation.ApiErrors at /moderator/moderation/:category_id/api_errors (moderators of the community or admins with moderator flag), linked from the moderation page.

**#406 resolved 2026-10-28** from wisspod's ProcessWire dump (field_podcast_panoptikum_id / field_podcast_feed_url / field_title, keyed by pages_id): 53009 BauertothePeople → merged into 52189, 52939 cliocast → 52886, 200 Forschungsquartett → 279 (found via alternate_feeds; all three survivors in category 106). 54 SozioPod (old feedburner URL) → 52011 (alternate feed; user remembered it as "removed on agreement", data shows a merge). wisspod has to update all four ids itself (user prefers that over renumbering podcasts back). #407 (idea, not decided): record merges so the 404 can name the successor id.

**Follow-up (2026-10-28, 40f40254, deployed + verified on prod: 1210 seed rows, a new admin delete got recorded):** table `former_podcasts` instead of #407: #408 id (old podcast id), title, feed_url, new_id (nullable), deleted_at; written in admin PodcastController.delete and PodcastMerge.merge. #409 a merge repoints rows with new_id = merged id to the new target. #410 API keeps the 404, message + meta name the new id (no redirect/serving). #411 backfill: 6 merges from wisspod's dump (54→52011, 74→77 Sprechkontakt, 200→279, 415→25851, 52939→52886, 53009→52189) + prod journal (`⚠️ Deleted podcast id: title`, `Podcast merge from -> to:` log lines); 8 truly deleted wisspod ids: 23147, 46987, 51385, 51813, 51852, 52245, 52246, 52936. Extracted dump list in session scratchpad wisspod_podcasts.json (dump itself deleted). #414 data-confirm on the deprecated page's Delete for community podcasts (#415 not chosen). #417 merge only in the direction where the community podcast survives when just one is in a community (#416/#418 not chosen). User: "all best effort".

Built: PanWeb.FormerPodcast (record/2 before delete — in merge before move_feeds, inside the transaction; repoints earlier rows; not_found/1 → {detail, meta}), seed migration reads priv/repo/data/former_podcasts.json (1210 rows from journal + wisspod dump, chains resolved, 53065→53058 deleted later so new_id nil; existing ids skipped, journal has no dates so deleted_at nil). #417 lives in PodcastMerge.merge/2 (error message, not a UI filter) via Community.titles_for_podcast/1. Test DB also gets the seed rows: don't assert absence of a FormerPodcast for a sequence id.

**Feed errors explained 2026-10-28 (open, user comes back one by one):** Modellansatz 185 `http://modellansatz.de/rss/` now an Apache directory listing, feed files still there (index.rss 200, modellansatz.rss, english.rss) → #419 change feed URL after comparing index.rss vs modellansatz.rss. Lesekuren 51810 WordPress 500, last ep 2025-01; Nahostcast 46997 yasmin-kollektiv.org 503, last ep 2024-09 → #420 likely ended, wisspod may archive. PRIF talk 52940 blog.prif.org → redirect to "under construction" 404 → #421 wait/ask PRIF. #422 do nothing. Occasional BredowCast/#digdeep/45 Minuten were transient (200 RSS on recheck).
#423 plain labels instead of action names in the "Endpoints" column: not wanted (user: fine as is, "show" = podcast data, "trigger_episode_update" = fetch new episodes).
#424 restore-previous dropdown + #425 URL edit keeps old URL/resets caching on the moderator feed page (Feed.change_url/2 shared with restore_alternate/2), #427 no feed check before saving (user: trust moderators); committed 9a24d780 2026-10-28, deploy pending. #419 checked: index.rss and modellansatz.rss identical (256 eps, newest 2026-08-21) → recommended http://modellansatz.de/rss/modellansatz.rss; feed's atom self still points to broken /rss/.
"Fix feed" link per row (8603fbe9). #428 "Remove from community" button on the API error page (CategoryPodcast.delete, confirm, podcast stays; moderators never delete podcasts — user rule), committed 2026-10-28. NEXT: #429 why failure_count is 0 on PRIF talk/Lesekuren/Nahostcast despite stored errors (all updated 2026-10-26 23:23, intervals 98–168 h) — check timestamps/data first, no theorizing; user wants to rely on retirement after the 10th failure.
