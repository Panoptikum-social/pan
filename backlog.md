# Backlog

Open work items and pending design decisions, kept here (rather than only in
Claude's per-machine memory) so they survive across computers. Last synced
2026-08-29.

---

## 1. Community categories + moderation redesign (in progress)

Status: **Phase A (schema/backend foundation) shipped to prod 2026-08-29,
commit `69f52125` "cut over to communities, part A/1" — DB-verified correct
in prod via the admin interface (`moderations` and `communities` both
checked, 100% correct). Everything below "Shipped in Phase A" is still open.**

### Background

"Moderation" was purpose-built for one specific community: category `106`
"Wissenschaftspodcasts.de" (a child of category `105` "👩 👨 Community"), the
community of German-speaking science/knowledge podcasts and podcasters. Category
105 has 3 more children that had zero moderators as of this writing:
"Kulturkapital - Museumspodcasts" (113), "Podcasterei.at" (115), "Frauenstimmen"
(142) — other communities waiting on a moderator-granting flow that still doesn't
exist yet (granting is still console/DB-only).

Current-state findings that still motivate the rest of the redesign:
- The frontend still doesn't know `Community` exists — `category_frontend_controller.ex`
  and `category/show.ex` still gate on the old hardcoded string match
  (`category.parent.title == "👩 👨 Community"`), not on whether a `Community` row
  exists. Nothing user-facing has changed yet.
- Category↔podcast membership is still 100% feed-driven (`itunes:category`, via
  `Pan.Parser.Category.persist_many/2`), append-only — nothing ever removes a
  podcast from a category, and there's no UI (moderator or admin) to manually
  add/remove membership. The only admin category tool is category merge
  (`lib/pan_web/live/admin/category/merge.ex`).
- The moderator UI (`/my_moderations` → `/moderation/:id` → per podcast/episode/feed
  edit) still uses a fully generic reflection-based `RecordForm` exposing every
  scalar column on the record (including things like `blocked`, `retired`,
  `update_paused`, `failure_count`) — no field allowlist yet, no association
  editing. No `PanWeb.Journal` audit trail either, but that's now a settled decision
  (see below), not an open question.

### Shipped in Phase A

- `PanWeb.Community` schema (`title`, `website`, `description`,
  `fediverse_address`, `belongs_to :category`, unique per category — this *is* the
  "is this a community" flag now, replacing the earlier `is_community` boolean
  idea). Category 105 itself will never get a `Community` row (pure navigation
  node, confirmed).
- Seeded in prod for all 4 known/candidate communities: 106
  (Wissenschaftspodcasts.de, the only one with moderators so far), 113
  (Kulturkapital - Museumspodcasts), 115 (Podcasterei.at), 142 (Frauenstimmen).
  The seed migration is prod-only (no-ops on QA via `config :pan, :environment`,
  and per-category no-ops anywhere that category doesn't exist, so it's also safe
  on test/synthetic DBs).
- `moderations` gained a `community_id` FK; the 3 existing moderator rows were
  backfilled onto it. `many_to_many :moderators` moved off `Category` onto
  `Community`. Went further than originally planned: `PanWeb.Moderation` no
  longer has a `category_id` field at all, and as of 2026-08-29 the DB column
  itself is gone too (fully reversible drop — `down/0` repopulates it from
  `community_id`, so nothing was lost) — the schema's real identity is now
  `{community_id, user_id}`, category is reached via
  `moderation.community.category`, and `Moderation.get_by_catagory_id_and_user_id/2`
  joins through `:community` internally while keeping its `category_id`-based
  interface (the `/moderation/:id` URL scheme is unchanged).
- `follows` gained a `community_id` FK; `Community.follow/2` / `Community.follows/1`
  mirror `Category.follow/2` / `Category.follows/1`. **Not wired into any UI yet**
  — `FollowButton`/`FollowController` don't know about `Community`, since there's
  no community-facing page to follow from yet.
- Two previously-open decisions got resolved along the way: no `PanWeb.Journal`
  audit trail for moderator actions (decided out of scope); the `RecordForm` field
  allowlist for moderators is in scope for this work, just not implemented yet
  (see below).
- `Community.personas/1` — derived membership (a Persona counts as a member if it
  contributes, any role, to any podcast under the community's category, "because
  they are already producing, in contrast to the passive listeners" — no manual
  override of this list). Turned out simpler than expected: a plain 3-hop Ecto
  `has_many :personas, through: [:category, :podcasts, :contributors]` works
  directly — Ecto auto-generates `SELECT DISTINCT` for the chained many-to-many, no
  hand-written query needed. Verified against real data (498 distinct personas for
  Wissenschaftspodcasts.de, zero duplicates; 16 for a zero-moderator category).
  Phase A is now fully complete.

### Still to do

- **Replace the hardcoded community check** — swap
  `category.parent.title == "👩 👨 Community"` in `category_frontend_controller.ex`
  and `category/show.ex` for a real `Category.has_community?/1` (or preloaded
  `:community`) check. Until this lands, `Community` existing in the schema
  doesn't change any user-facing page.
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
