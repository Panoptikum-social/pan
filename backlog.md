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
feed" workflow) hasn't been started.**

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

- **Moderator "add a feed" workflow** (unchanged from the original design, still
  fully pending):
  1. Moderators can enter a brand-new feed URL directly from their moderation area.
     This **skips the existing `PanWeb.FeedBacklog` review queue entirely**
     (confirmed: "yes, skip the review") — no backlog row, straight to import. (For
     context: `FeedBacklog` today lets plain users submit a URL via
     `FeedBacklogFrontendController`, but nothing auto-processes it — an admin has
     to manually visit `/feed_backlog` and click `import`/`import_100`, which calls
     `Pan.Parser.RssFeed.initial_import/2`.)
  2. Immediate parsing: the moderator's submitted URL runs
     `Pan.Parser.RssFeed.initial_import/2` **synchronously** (same call the admin
     `feed_backlog_controller.ex` `import` action already uses).
  3. Before running `initial_import`, dedupe the URL against known feeds using the
     existing `PanWeb.Feed.clean_and_best_matching/1`. If it already matches a known
     podcast: **skip `initial_import`**, show the moderator "we already know that
     podcast and added it to your moderation", auto-attach the category (point 5),
     and additionally trigger `Pan.Parser.Podcast.update_from_feed/1` (the full
     re-parse pathway) **synchronously** so Panoptikum's copy is refreshed
     immediately. Confirmed synchronous over backgrounded (`Task.start`), even
     though this can be slow for large back catalogs (582 episodes for podcast
     19664 in testing). **Hard prerequisite:** backlog item 2 below (stale
     contributor cleanup, with a claimed-persona-safe redesign — the first attempt
     was rejected, see item 2) must land before this branch ships, since this
     workflow is what makes that bug routine instead of hypothetical.
  4. After a successful new import, auto-assign the new podcast to the moderator's
     category — `itunes:category` from the feed itself can't be relied on, since
     feed authors have no way to know about Panoptikum-specific curation categories
     like "Wissenschaftspodcasts.de".
  5. "Add existing podcast to moderation" / "remove podcast from moderation" — plain
     manual `categories_podcasts` add/remove for (moderator's category, podcast).
     `PanWeb.CategoryPodcast.get_or_insert/2` already exists and is unused by any
     UI — covers "add." **No delete function exists yet** for `CategoryPodcast` —
     needs adding for "remove."
  6. `RecordForm` field allowlist — hide `blocked`/`retired`/`update_paused`/
     `failure_count` (and anything else in that vein) from the moderator-facing
     `RecordForm` specifically (`lib/pan_web/components/moderation/record_form.ex`);
     the admin `RecordForm` (`lib/pan_web/admin/record_form.ex`) is a separate
     component and keeps full access. Decided in scope for this workflow, not yet
     implemented — should land alongside it, since this workflow is what expands
     what moderators can trigger. No `PanWeb.Journal` writes anywhere in this flow
     (decided out of scope).

### Phase E — Proper Community show page (new, added 2026-08-29)

Phase D bolted the community showcase onto `category/show.ex` — reusing the
category page for two conceptually different things (browsing a category's
podcasts vs. a community's identity) saved a few lines but isn't clean. Moving to
a real separation:

1. New `/communities/:id` route (keyed on the `Community`'s own id, not
   `category_id`) → `Live.Community.Show` — the community identity page: moved
   out of `category/show.ex`: title, description, `website` (`rel="me"`),
   `fediverse_address`, moderators, full member persona list, Follow button. Links
   out to the category page (`/categories/:id` or `:categorized`/
   `:latest_episodes`) for actually browsing the community's podcasts, rather than
   duplicating that grid.
2. `category/show.ex` — remove `@community`/`@community_personas` and the
   showcase panel entirely; back to pure category browsing, unaware of
   `Community` as a concept.
3. `/communities` index page — links to `/communities/:id` instead of
   `/categories/:id`.
4. Hide community-only categories from `/categories` (`Category.tree/0` /
   `Live.Category.Tree`) — scoped to just that page, not `stats_tree`, the
   category merge admin tool, or breadcrumbs elsewhere, which still need to see
   everything. Category 105 ("👩 👨 Community") itself also disappears from that
   page once all its children are filtered out and it'd otherwise show as an
   empty dead-end entry.

---

## 2. Stale contributor/person role cleanup on feed re-parse

Status: **spec written, not implemented.** Now higher priority than originally
scoped — see below.

Adding `podcast:person` support (channel/item-level RSS tag, implemented in
`lib/pan/parser/analyzer.ex` and `lib/pan/parser/contributor.ex`, tested against
podcast 19664) means feed-derived contributors can now carry arbitrary roles
(`host`, `guest`, …) instead of the single hardcoded `"contributor"` role every
feed-derived contributor used before.

The pre-existing delete-before-reinsert cleanup only ever targets the literal role
string `"contributor"`:
- `lib/pan/parser/persistor.ex`, `update_from_feed/2`:
  `PodcastContributor.delete_role(podcast.id, "contributor")`
- `lib/pan/parser/episode.ex`, `update_from_feed_one/2`:
  `Contributor.delete_role(episode.id, "contributor")`

`owner`/`managing_editor`/`author` are proper delete-then-reinsert singletons and
are unaffected. Consequence: on a re-parse, any `Engagement`/`Gig` whose role isn't
literally `"contributor"` (i.e. anything from `podcast:person`) never gets cleaned
up — a role change between two feed versions orphans the old row, and a person
dropped from the feed is never removed.

**Proposed fix:** generalize the cleanup from "delete rows matching role ==
`\"contributor\"`" to "delete all feed-derived contributor/person rows for this
podcast/episode" (everything except `owner`/`managing_editor`/`author`) before
re-persisting fresh from the parsed map. Needs a delete-by-exclusion variant on
`Pan.Parser.PodcastContributor` (scoped to `podcast_id`) and
`Pan.Parser.Contributor` (scoped to `episode_id`).

Acceptance criteria: role changes update in place (no duplicate rows), removed
people get their `Engagement`/`Gig` deleted, `owner`/`managing_editor`/`author`
untouched, existing `atom:contributor`-only feeds behave exactly as before,
`mix test`/`format`/`credo` clean.

**Why this got more urgent:** originally this only blocked *a hypothetical future
bulk re-parse* of all existing feeds. Since the moderation redesign above (item 1,
workflow step 3) will trigger `Persistor.update_from_feed` synchronously and
routinely — every time a moderator adds an already-known podcast to their community
— this gap will surface in normal use, not just a one-off backfill. Worth
sequencing this fix alongside the moderation work rather than treating it as
unrelated backlog.

---

## 3. Other open backlog items

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

### (Deprioritized idea, probably not pursuing) Alternate-feed fallback on fetch failure
Should a broken feed fetch fall back to trying a podcast's old, superseded
`alternate_feeds` URLs before failing/retiring? Discussed, not decided, but leaning
against: `alternate_feeds` records URLs a provider deliberately moved *away* from,
which essentially never get reverted, so a fallback rarely finds anything useful —
and if an old URL is still resolving but stale/parked, a fallback fetch would
"succeed" against stale content, reset `failure_count`, and mask the
`retired: true` signal that's supposed to flag something needing human attention.
Would also need the same redirect-loop protection as the main fetch path. If this
resurfaces, start from "what's the actual likelihood an old, superseded URL is
still serving *current* content" — that's the crux, and it's low.
