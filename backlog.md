# Backlog

Open work items and pending design decisions, kept here (rather than only in
Claude's per-machine memory) so they survive across computers. Last synced
2026-08-28.

---

## 1. Community categories + moderation redesign (in progress)

Status: **design discussion, not yet written as a formal spec or implemented.**
Everything below reflects what's been agreed in conversation so far; not started in
code.

### Background

"Moderation" was purpose-built for one specific community: category `106`
"Wissenschaftspodcasts.de" (a child of category `105` "👩 👨 Community"), the
community of German-speaking science/knowledge podcasts and podcasters. Confirmed
via DB query — all 3 existing `moderations` rows are scoped to category 106, none to
any other category. Category 105 already has 3 more children with zero moderators
assigned: "Kulturkapital - Museumspodcasts" (113), "Podcasterei.at" (115),
"Frauenstimmen" (142) — other communities waiting on a moderator-granting flow that
doesn't exist yet.

Current-state findings that motivate the redesign:
- "Community" isn't a real concept in the schema today — it's a hardcoded string
  match on `category.parent.title == "👩 👨 Community"` in
  `lib/pan_web/frontend_controller/category_frontend_controller.ex` and
  `lib/pan_web/live/category/show.ex`.
- Category↔podcast membership is 100% feed-driven (`itunes:category`, via
  `Pan.Parser.Category.persist_many/2`), append-only — nothing ever removes a
  podcast from a category, and there's no UI (moderator or admin) to manually
  add/remove membership. The only admin category tool is category merge
  (`lib/pan_web/live/admin/category/merge.ex`).
- `PanWeb.Moderation` is a bare `{category_id, user_id}` join table (no role,
  granted-by, or timestamp columns). **No UI anywhere creates a `Moderation` row** —
  granting someone as a moderator is console/DB-only today.
- The moderator UI (`/my_moderations` → `/moderation/:id` → per
  podcast/episode/feed edit) uses a fully generic reflection-based `RecordForm`
  exposing every scalar column on the record (including things like `blocked`,
  `retired`, `update_paused`, `failure_count`) — no field allowlist, no association
  editing, and no audit trail (doesn't touch `PanWeb.Journal`, despite that model
  existing for exactly this).

### Design decisions made so far

**New `PanWeb.Community` schema** — this *replaces* the earlier idea of an
`is_community` boolean/type flag on `Category`; the existence of a `Community` row
for a category **is** the flag.

- Fields: `title`, `website`, `description`, `fediverse_address` (matches the field
  name `Persona` already uses, not `fediverse_handle`).
- `belongs_to :category` — exactly one `Community` per community-category (e.g.
  category 106 gets one). The top-level category 105 ("👩 👨 Community") will
  **never** get a `Community` row — confirmed explicitly, it stays a pure navigation
  node forever.
- `many_to_many :moderators, through: "moderations"` — **moved off `Category` onto
  `Community`** (moderation was always community-scoped in practice anyway). The
  `moderations` join table gets a `community_id` FK.
- `has_many :users` (community members — podcasters, moderators, or just plain
  users) — implemented as **another nullable column on the existing generic
  `follows` table** (`community_id`, alongside its existing `podcast_id`/
  `episode_id`/`persona_id`/`category_id`/`user_id`), reusing `Follow`'s toggle
  semantics (join = follow, leave = unfollow). The user treats "follow" and
  "subscribe" as synonyms here — no new table, no approval workflow.
- `has_many :personas` — **derived, not a stored join table.** A Persona counts as
  an (active) community member if it's a contributor (any role) on any podcast under
  the community's category — "because they are already producing, in contrast to
  the passive listeners." Expressible as a chained `has_many :personas, through:
  [...]` off `Category.podcasts` (many_to_many via `categories_podcasts`) →
  `Podcast.contributors` (many_to_many via `engagements`, already exists) — both
  hops already exist as associations, no new table needed. No manual override of
  this list.

**Moderation workflow improvements** (extends the "manual category curation" gap
above with a concrete moderator-facing flow):

1. Moderators can enter a brand-new feed URL directly from their moderation area.
   This **skips the existing `PanWeb.FeedBacklog` review queue entirely**
   (confirmed: "yes, skip the review") — no backlog row, no audit trail via that
   table, straight to import. (For context: `FeedBacklog` today lets plain users
   submit a URL via `FeedBacklogFrontendController`, but nothing auto-processes it —
   an admin has to manually visit `/feed_backlog` and click `import`/`import_100`,
   which calls `Pan.Parser.RssFeed.initial_import/2`.)
2. Immediate parsing: the moderator's submitted URL runs
   `Pan.Parser.RssFeed.initial_import/2` **synchronously** (same call the admin
   `feed_backlog_controller.ex` `import` action already uses).
3. Before running `initial_import`, dedupe the URL against known feeds using the
   existing `PanWeb.Feed.clean_and_best_matching/1` (already exists, used today on
   the admin backlog's `show` page). If it already matches a known podcast: **skip
   `initial_import`**, show the moderator "we already know that podcast and added it
   to your moderation", auto-attach the category (point 5), and additionally
   trigger `Pan.Parser.Podcast.update_from_feed/1` (the full re-parse pathway — see
   item 2 below) **synchronously** so Panoptikum's copy is refreshed immediately.
   Confirmed synchronous over backgrounded (`Task.start`), even though this can be
   slow for large back catalogs (582 episodes for podcast 19664 in testing).
4. After a successful new import, auto-assign the new podcast to the moderator's
   category — `itunes:category` from the feed itself can't be relied on, since feed
   authors have no way to know about Panoptikum-specific curation categories like
   "Wissenschaftspodcasts.de".
5. "Add existing podcast to moderation" / "remove podcast from moderation" — plain
   manual `categories_podcasts` add/remove for (moderator's category, podcast).
   `PanWeb.CategoryPodcast.get_or_insert/2` already exists and is unused by any UI —
   covers "add." **No delete function exists yet** for `CategoryPodcast` — needs
   adding for "remove."

### Still open / not yet decided
- Whether the missing audit-trail gap (moderator edits not going through
  `PanWeb.Journal`) gets addressed as part of this work — flagged, not yet answered.
- The generic `RecordForm`'s lack of a field allowlist for moderators (they can
  currently edit *any* scalar column, including things like `blocked`/`retired`) —
  flagged, not yet discussed further.
- Whatever part 3+ of the design discussion brings (conversation was still ongoing
  when this file was written).

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
