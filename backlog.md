# Backlog

Open work items and pending design decisions, kept here (rather than only in
Claude's per-machine memory) so they survive across computers. Last synced
2026-08-29.

---

## 1. Community categories + moderation redesign (in progress)

Status: **Phases A (schema/backend), B (public pages know `Community` exists), D
(public community showcase + `/communities` index + sidebar nav), and E (moved to
a dedicated `/communities/:id` show page, separate from `category/show.ex`, and
hid community-only categories from the public `/categories` list) are fully
shipped and deployed — see the code, not repeated here. Phase C (moderator "add a
feed" workflow) is in progress — steps 1-2 shipped, see below.**

### Background

"Moderation" was purpose-built for one specific community: category `106`
"Wissenschaftspodcasts.de" (a child of category `105` "👩 👨 Community"), the
community of German-speaking science/knowledge podcasts and podcasters. Category
105 has 3 more children that had zero moderators as of this writing:
"Kulturkapital - Museumspodcasts" (113), "Podcasterei.at" (115), "Frauenstimmen"
(142) — other communities waiting on a moderator-granting flow that still doesn't
exist yet (granting is still console/DB-only).

Current-state findings that still motivate the rest of the redesign:
- Category↔podcast membership is still 100% feed-driven (`itunes:category`, via
  `Pan.Parser.Category.persist_many/2`), append-only — nothing ever removes a
  podcast from a category, and there's no UI (moderator or admin) to manually
  add/remove membership. The only admin category tool is category merge
  (`lib/pan_web/live/admin/category/merge.ex`).
- The moderator UI (`/my_moderations` → `/moderation/:id` → per podcast/episode/feed
  edit) still uses a fully generic reflection-based `RecordForm` exposing every
  scalar column on the record (including things like `blocked`, `retired`,
  `update_paused`, `failure_count`) — no field allowlist yet, no association
  editing. No `PanWeb.Journal` audit trail either — settled decision, out of scope,
  not an open question.

### Still to do

- **Moderator "add a feed" workflow** — in progress:
  1. ✅ `CategoryPodcast.delete/2` added (didn't exist before).
  2. ✅ Feed-URL submission form on `Live.Moderation.Moderate`
     (`lib/pan_web/live/moderation/moderate.ex`), `phx-submit="add-feed"`. Dedupes
     via `PanWeb.Feed.clean_and_best_matching/1`: no match → synchronous
     `Pan.Parser.RssFeed.initial_import/1`, auto-attaches the category on success;
     match found → skips import, auto-attaches the category, and synchronously
     re-parses via `Pan.Parser.Podcast.update_from_feed/1` (matching the exact
     `{:ok, message} / {:error, message}` handling the admin databrowser's own
     `update_from_feed` action already uses, including its `Search.Podcast.update_index/1`
     + `Podcast.remove_unwanted_references/1` follow-up on success). The grid
     refreshes via `send_update(ModerationGrid, records: [])`, reusing the same
     mechanism already used for the `:count` refresh. Live-verified end to end
     (real dedupe match, real synchronous re-parse, real flash message) — including
     a real, permanent, wanted addition: podcast 52871 ("bild der wissenschaft
     PODCAST", from user 1284's own subscriptions) attached to category 106.
     Skips `PanWeb.FeedBacklog` entirely, as designed.
  3. "Remove podcast from moderation" — a button on the moderation grid using
     `CategoryPodcast.delete/2` (point 1). Not yet wired into the UI.
  4. "Add existing podcast to moderation" — browsing/picking an already-known
     Panoptikum podcast (distinct from point 2, which already covers "paste a
     known podcast's feed URL"). Needs a search/picker UI that doesn't exist yet;
     design still open.
  5. `RecordForm` field allowlist — hide `blocked`/`retired`/`update_paused`/
     `failure_count` (and anything else in that vein) from the moderator-facing
     `RecordForm` specifically (`lib/pan_web/components/moderation/record_form.ex`);
     the admin `RecordForm` (`lib/pan_web/admin/record_form.ex`) is a separate
     component and keeps full access. Not yet implemented.

---

## 2. Other open backlog items

### Two latent bugs in `PanWeb.Image.download_thumbnail/3` (found 2026-08-29)
Found while live-testing the moderator feed-add workflow (item 1) — both were
masked here only because this *local bare-metal dev machine* never had
`/var/phoenix` or ImageMagick set up (now fixed locally). Checked QA's
`Dockerfile`/`docker-compose.yml`: both already correctly provisioned
(`RUN mkdir -p /var/phoenix/pan-uploads && chown pan:pan ...`, `imagemagick`
installed, a named volume mounted over that path) — nothing to fix there, and
prod's bare-metal setup evidently has this right too, since neither bug has
ever surfaced. Still real code bugs, just currently inert wherever the infra
happens to be correctly provisioned — flagging only, not otherwise in scope:
1. `lib/pan_web/models/image.ex:81` — `File.mkdir_p(target_dir)` uses the
   non-bang variant and its `{:error, reason}` return is silently discarded, so
   the very next line's `File.write!/2` fails with a confusing "no such file or
   directory" instead of surfacing the real problem, if that directory/mount
   ever isn't there or isn't writable.
2. Same file, the `try/catch` around `Mogrify.save/2` (comment: *"we fail
   silently, as we did before mogrify raised errors"*) pattern-matches
   `{error, {message, _}}` / `{error, message}` throw shapes, but current
   Mogrify (0.9.3) raises a plain `RuntimeError` — the catch clauses don't match
   a raised exception's shape, so any real Mogrify failure (corrupt image,
   missing binary, etc.) propagates uncaught instead of failing silently as the
   comment says was intended.

### Move qa/prod secrets to `config/runtime.exs`
There's no `config/runtime.exs` at all today — the full config chain
(`config.exs` → `qa.exs`/`prod.exs` → `qa.secret.exs`/`prod.secret.exs`) is
compile-time only, so secrets (DB password, `PanWeb.Endpoint` `secret_key_base`,
mailer creds) end up baked in plaintext inside the release/image itself. Standard
modern Phoenix (1.6+) generates `runtime.exs` by default; this app predates/diverges
from that.

**Fix when picked up:** add `config/runtime.exs`, move secret-bearing keys out of
`qa.secret.exs`/`prod.secret.exs` into `System.get_env/1` reads gated by
`config_env()`, update `docker-compose.yml` to pass them via `environment:` instead
of baking them into the build context, update `DOCKER.md` accordingly. Touches both
the QA Docker flow and the bare-metal prod deploy — test both.

### Parallelize the sequential podcast-update job
Filed in Gitea (exact issue not tracked here — check Gitea for the full text).
`Pan.Job.ImportStalePodcasts` processes one overdue podcast at a time, fully
sequentially. An earlier parallel implementation got penalized — CDNs/podcast hosts
flagged it as a DDoS, since many independent podcasts share backends (Libsyn,
Buzzsprout, etc. host thousands of shows each) — so it was reverted.

**Solution strategy discussed:** group by **registrable domain (eTLD+1)**, not raw
hostname (subdomains share a backend) or IP (shared CDN edges make IP too coarse,
and misses the actually-vulnerable un-CDN'd small hosts). Bounded worker pool
(~5-10 concurrent), ETS table tracking per-domain last-started-at, skip candidates
whose domain is in-flight or was hit within a courtesy window, fall back to today's
idle-sleep behavior when nothing qualifies.
