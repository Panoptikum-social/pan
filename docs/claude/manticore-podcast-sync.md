On 2026-10-01 the user reported podcasts missing from search on prod ("Zeit für Wissenschaft") and stale thumbnails (AstroGeo). That led to a full overhaul of how the Manticore index stays in sync. Commits run from 73700044 to cc7ab780 on main. Every numbered item (1–29) is closed.

## How it works now
- **Push model:** each model has a `full_text` flag. `Pan.Job.PushMissingSearchIndex`, a prod-only job, runs every 3 minutes and bulk-pushes rows with `full_text = false`. To get something re-indexed, set its flag to `false`.
- **Bulk actions:** the bulk push uses **`replace`** for all four models. `insert` failed with "duplicate id", so a reset could never refresh a stale document. `manticore_struct/1` returns a bulk **`delete`** line for blocked podcasts, episodes of blocked podcasts and redirected personas. A bulk delete of an id that isn't in the index returns 200 with no errors.
- **Copies:** documents hold copies of other models' data. Episode documents carry the podcast's title, languages and categories, plus their gigs with persona names. Podcast documents carry category titles and engagements with persona names. Persona documents carry podcast titles and episode ids. Search results render these copies as links ([lib/pan_web/live/search.ex](../../lib/pan_web/live/search.ex)).
- **Who re-flags what:**
  - **Feed update** (`Persistor.update_from_feed`): the podcast; its episodes if the podcast's title, languages or categories changed (`Search.Episode.podcast_data/1`); its personas before and after the update (`Search.Persona.ids_for_podcast/1`).
  - **Episode changes from the feed:** an episode whose text changed (`insert_or_update`) or whose gigs changed (`gigs_data/1`, compared as persona and role; gig ids are ignored because the author gig is re-inserted on every update).
  - **`delta_import`:** the podcast's personas. A new episode is re-flagged once its gigs are saved.
  - **Admin and moderation form save:** `QueryBuilder.update_index/3`. Its `reset_copies` handles a category rename, a podcast title or `blocked` change, and a persona rename.
  - **`CategoryPodcast` insert or delete, and category merge:** the podcast(s) and their episodes.
  - **Persona rename, merge or delete:** `Search.Persona.copy_ids/1` plus `reset_copies/1`. For merge and delete, the ids are collected *before* the gigs move or disappear.
  - **Large re-flags run in a background `Task`:** category and persona copies, because "Sports & Recreation" alone covers ~3.8 million episodes.
- **Orphans:** `Pan.Search.delete_orphans/2` pages through the ids Manticore holds, 10,000 at a time, and deletes those missing from the DB. Episodes take about 1 minute. The admin button runs it in a Task. Episodes deleted during a feed update are now removed from the index as well.

## Prod runbook
- **Stop the job while running a reset:** `Supervisor.terminate_child(Pan.Supervisor, Pan.Job.PushMissingSearchIndex)`, then `restart_child` afterwards. `batch_reset()` loops until no flag is `true`, so it competes with the job.
- **Count check snippet:** compares DB vs. Manticore per model. The DB side leaves out blocked podcasts (`is_nil(p.blocked) or p.blocked == false`), their episodes, and redirected personas. On 2026-10-01 after the full re-index it matched exactly: 490 categories, 33,517 podcasts, 229,880 personas, 8,558,220 episodes.
- **Timings:** a full episode re-push takes a few hours on prod, and about 77 minutes in dev for 8.5 million episodes.

## Status
- **Deployed:** everything committed (user confirmed 2026-10-09). Don't list commits as "not yet deployed" from this note again.
- **All formerly untested paths verified on dev 2026-10-12 (#59, closed):** orphan button (removed 3,255 podcast + 450,480 episode orphans on dev), category merge, persona merge and delete (via real admin routes), API persona update/redirect/cancel_redirect (via token), persona thumbnail job. Index side correct in every case.
- **Found while testing, not Manticore (open, numbered):** #119 (fixed 2026-10-12, fb5bc307, deployed) `Category.merge/2` didn't move `communities.category_id`; test env now points manticore_url at localhost:1 so tests never hit the dev index; #120 persona merge deletes the *target's* manifestations (`persona_controller.ex` `m.persona_id == ^to_id`, legacy since 2021), source's claims are lost via cascade (fixed 2026-10-12, 042b4e15, deployed: claims move to target, user_id inherited, merge refused if both owned by different users).
- **Not covered:** a moderator changing `image_url` doesn't re-cache the thumbnail (`thumbnailed` stays `true`). That's a thumbnail-caching issue, not on any list.

## Dev
- **2026-10-12:** user restores only Postgres from prod, not Manticore — the dev index is NOT re-built after restores, and that's fine for testing: push the test records first (baseline), then compare. Leftover dev-only artifacts: stale episode docs whose ids prod later reused (seen 9), ~89 categories missing from the dev index.
- **Fully re-indexed by hand on 2026-10-01; all counts matched then.** Before that, the dev index was a snapshot from about 2025-04-06 while the dev DB is a newer prod dump with prod's flags. That caused misleading dev counts and documents whose ids belonged to other episodes.
- **The job doesn't run in dev** ([dev-background-jobs-disabled](dev-background-jobs-disabled.md)), so after dev changes run `Pan.Search.push_missing()` by hand.

**Why:** the user found real search bugs on prod. The design rule throughout: flag rows and let the job push them, rather than indexing inline.
**How to apply:** when touching code that changes data copied into another model's search document, re-flag those documents. Check against the "who re-flags what" list above. Related: [manticore-search](manticore-search.md), [manticore-delete-sync](manticore-delete-sync.md)
