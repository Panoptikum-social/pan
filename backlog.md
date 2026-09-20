# Backlog

Open work items and pending design decisions, kept here (rather than only in
Claude's per-machine memory) so they survive across computers. Last synced
2026-09-19.

---

## Open backlog items

### Project #1: extract the pure feed-parsing core out of `lib/pan/parser/` (found 2026-09-01)
Prompted by the `scrub/1` mixed-content crash (`Pan.Job.RefreshPodcastMetadata`,
fixed same day, commit `cf82e1f2`). Assessed feasibility of pulling the feed
parser out as its own Elixir package — full writeup in that day's conversation.
Verdict: the directory splits cleanly into a DB-free "XML → map" core
(`analyzer.ex`, `iterator.ex`, `helpers.ex`, `rss_feed.ex`'s `xml_to_map`/
`parse_to_map`, `my_date_time.ex`, ~1,800 LOC, depends only on `quinn`/
`html_sanitize_ex`/`timex`) versus a majority that's genuinely Panoptikum
business logic (`persistor.ex` + the `podcast`/`feed`/`episode`/`category`/
`language`/`contributor`/`author`/`persona`/`podcast_contributor`/
`alternate_feed`/`chapter`/`enclosure` modules — Ecto upserts, counters,
thumbnail caching, cascade-delete guarding, PubSub). `download.ex` sits in
the middle: its redirect-following calls into `Feed.check_for_redirect_loop/3`,
which queries the `alternate_feeds` table — not actually DB-free today.

Two-phase project, phase 1 motivated entirely on its own (isolation/
testability), phase 2 optional and only worth it if genuine reuse elsewhere
materializes:

**Phase 1 — isolate & test the parsing core (in-repo, no package yet).**
- Move `feed_urls/0` out of `helpers.ex` (its one stray `Repo.all` call).
- Make `Download`'s redirect-loop check injectable/optional so fetching
  doesn't require `Feed.check_for_redirect_loop`.
- Give the output map a documented, consistent shape (today it mixes string
  and atom keys, e.g. `map["owner"]` vs. `map[:episodes]` in `persistor.ex`).
- Add real test coverage for `Analyzer`/`Iterator`/`Helpers` — none exists
  today; this is the main payoff of phase 1 and would have caught the
  `scrub/1` crash before prod.

**Phase 2 — actual package extraction (only if reuse elsewhere shows up).**
- Split the now-isolated core into its own `mix.exs` (path or git dep first;
  Hex.pm publish only if there's real external interest).
- No sunk cost from phase 1 either way — the boundary work is required for
  testability regardless of whether phase 2 ever happens.

---

### Project #2: public "check my feed" compliance tool (found 2026-09-01)
Follow-on idea from Project #1's discussion: a public-facing feature that
checks a podcast's feed against real standards — RSS 2.0
(validator.w3.org/feed/docs/rss2.html), Apple Podcasts
(help.apple.com/itc/podcasts_connect), Podcasting 2.0 (podcasting2.org),
podcast-standard.org — and reports where it falls short, plus (separately,
info-level) where Panoptikum silently tolerates non-standard constructs it
has learned to work around over the years (the ~70 date formats, entity/
angle-bracket fixups, mixed-content HTML scrubbing, etc. already in
`lib/pan/parser/helpers.ex` — that catalog of tolerances is *not* a standard
to check against, it's the mirror image: proof of what's actually out there).

**Access model — deliberate, not a generic open validator:** only checkable
for podcasts already present in the Panoptikum directory. This is intentional
incentive/motivation to add a podcast to Panoptikum in the first place, not
a public utility anyone can point at an arbitrary URL.

**Modularity — explicit personal goal, not just architecture hygiene:** user
wants a genuinely separate Elixir module/package for this (hasn't hand-built
a standalone Elixir module in ~8 years and wants the practice back). Rule
engine + rule definitions should live as an independent, testable library
that Pan depends on — not code interleaved into `pan_web`. User explicitly
does **not** want this sharing a runtime/codebase with the feed parser in
Project #1 — deliberately a separate project, even though the directory-
gating requirement above means Pan's web app still has to own the "is this
podcast actually listed" check and the UI around it.

**Open design tension to revisit when picked up:** "separate project" at the
ownership/deployment level is clear and agreed. Whether it should also mean
*reimplementing* feed XML/date/HTML parsing from scratch, vs. depending on
Project #1's extracted core as a library once phase 2 there lands, is not
yet decided — the risk of hand-rolling a second parser is quietly
re-deriving the same bugs (e.g. the `scrub/1` mixed-content crash from
2026-09-01) the hard way a second time. Worth an explicit call rather than
defaulting into it either way.

**Scope note carried over from the assessment:** encoding "the standards" is
itself an open-ended, ongoing-maintenance surface (Apple's page has no
changelog and drifts; Podcasting 2.0 keeps adding tags). Recommend rules as
data (`%{id, standard, severity, spec_url, check: fun}`, not scattered
`if`s), a narrow objectively-checkable v1 (required elements present, stable
GUID, `itunes:category` from Apple's real taxonomy, enclosure `type`/
`length` well-formed, artwork present in the right format, episode/season
numbering consistency), with fuzzier judgment-call checks and active
probing (HTTP HEAD on enclosures, fetching artwork for actual pixel
dimensions — same probe-then-report shape as the existing deprecation
check) deferred past v1.

**Decisions, 2026-09-19 (resolves the open design tension above):**
- Separate mix project named `check-my-feed`, imported by Pan as a
  dependency (path dep first). It parses the raw feed XML itself
  (Quinn/xmerl only, no Pan code) — Pan's parser deliberately fixes up bad
  feeds before parsing, which would hide exactly what this tool must report.
- The library takes an XML string and does no fetching. Pan downloads a
  fresh copy on every check (via `Download.get/2`, so the SSRF guard
  applies), since the owner may have just fixed the feed.
- Only logged-in users, only for podcasts listed in Panoptikum.
- v1 rules exactly as in the scope note (RSS 2.0 required elements + Apple
  basics). Podcasting 2.0, active probing, and the info-level "Pan tolerates
  this" report come later. JSON API later or never; v1 is a web page with
  results grouped by severity, each with rule id and spec link.
- Who may check a podcast, rolled out in three phases: **C** any logged-in
  user (first, nothing new to build), then **A** a user with a claimed
  persona that has a non-self-proclaimed gig on the podcast, then **B**
  real podcast claiming (proof of feed control, e.g. token in the feed or
  mail to the `itunes:owner` address). Note: only personas can be claimed
  today, there is no user-to-podcast ownership link.
- UI entry point decided: a "Check feed" link on the podcast page (logged-in
  users) leading to its own results page.

**Status 2026-09-19 — phase C built, dev only.** Library
`../check-my-feed` (repo `Panoptikum/check-my-feed`) has 5 RSS 2.0 rules and 17 Apple Podcasts rules (v1 scope complete);
Pan has `PanWeb.Live.Podcast.CheckFeed` at `/pan/podcasts/:id/check_feed`
(findings grouped by severity and rule, list of passed checks, "Check again").
Pan depends on the library via `{:check_my_feed, path: "../check-my-feed",
only: :dev}`, so nothing is visible in qa/prod yet.

**Still open, in suggested order:**
1. *Get out of dev-only:* decide how Pan depends on the library (git dep from
   code.informatom.com, Hex later), replace the runtime `apply`/
   `Code.ensure_loaded?` workaround in `check_feed.ex` with a direct call,
   verify the qa Docker build and the prod deploy script can fetch the
   dependency (the prod deploy script is the risky part).
2. *Access phase A:* only users with a claimed persona holding a
   non-self-proclaimed gig on the podcast may check it (phase C, any logged-in
   user, is what exists now).
3. *Access phase B:* real podcast claiming (proof of feed control, e.g. token
   in the feed or mail to the `itunes:owner` address). No user-to-podcast
   ownership exists today, only personas can be claimed.
4. *Later, agreed:* Podcasting 2.0 rules, active probing (HEAD on enclosures,
   artwork pixel size), the info-level "Panoptikum tolerates this" report,
   JSON API (maybe never).

**Apple rules, missing source material (2026-09-19) — user will provide it as
plain text or HTML (no JavaScript) so the rules can be checked against the real
wording:**
- Apple's *required tags* reference (`help.apple.com/itc/podcasts_connect/#/itcb54353390`,
  JavaScript-only, unreadable): which channel and episode tags are required vs.
  recommended, allowed values for `itunes:explicit`, `itunes:episodeType`,
  `itunes:episode`, `itunes:season`.
- Apple's *artwork requirements* (`podcasters.apple.com/support/artwork-requirements`
  links to spec pages we couldn't reach): formats, pixel size, color space, size
  limit.
- The list of *supported enclosure file types / MIME types* (no page found).

Then re-check `lib/check_my_feed/rules/apple.ex` against it: adjust severities
(several rules are only `:warning`/`:info` because Apple's wording wasn't
available), the supported-media-type list, and the artwork rule.

**Apple rules, notes (2026-09-19):** verified against Apple's pages: artwork,
enclosure (url/length/type), a never-changing guid per episode and at least one
episode are required; the category list and the two-category limit. Apple's
artwork-size, supported-file-type and tag-detail pages are JavaScript-only or
link elsewhere and could not be read, so everything else (language, explicit,
episodeType, numbering, media types, JPEG/PNG artwork) is severity warning/info
based on general knowledge. Artwork pixel size is not checked (needs a download;
part of the later "active probing" item). Assumes the `itunes:` prefix.

**Small known issues:**
- Some feed servers answer 403 to Panoptikum's user agent, so the page reports
  a failure although the feed is fine (2 of 12 sampled feeds).
- A rule counts as passed when it had nothing to check (e.g. the enclosure
  rule on a feed with no episodes); consider hiding those from "Passed".
- Library tests print an xmerl `[error] fatal` log line for the broken-XML
  test (Pan silences that via `Pan.LoggerFilters`, the library doesn't).
- Findings only cover the first feed of a podcast (`Feed.get_by_podcast_id/1`).

---

### PWA: asset caching + lock-screen media controls (found 2026-09-01)
Assessed making Panoptikum a PWA. Turns out most of the groundwork already
exists — `priv/static/config/site.webmanifest` is already linked in
`<head>` with `display: "standalone"` set, and a full icon set (16/32px
favicons, 180px apple-touch, 192px android-chrome, Safari pinned-tab SVG)
plus a clean 512×512 source logo (`panoptikum.social.svg`) already sit in
`priv/static/images/`, all apparently from a one-time favicon-generator
pass that was never fully finished. No service worker exists yet.

User's actual motivation was being able to create a Linux (Mint) desktop
menu-item shortcut for the site — that's satisfied by the cheapest tier
(fill in the manifest's empty `name`/`short_name`, add the missing 512px
icon, register a minimal service worker) and isn't itself blocked on
anything below; do that whenever, separately from this item.

This item is the next tier up, deliberately scoped to what's actually
useful for a podcast site without hitting LiveView's ceiling (a live
WebSocket connection is required for interactivity — no PWA/service-worker
trick makes Panoptikum's pages themselves work offline):

- Basic service-worker asset caching (CSS/JS/icons) so repeat loads are
  instant and there's a friendly offline fallback instead of a browser
  error page.
- Media Session API integration — OS-level lock-screen/notification
  playback controls (play/pause/skip, artwork) for whatever's currently
  playing, wired to the Podlove player's existing playback events
  (`registerExternalEvents` in `assets/js/podlove_player.js`). Frontend-only,
  no backend changes.

**Explicitly out of scope, decided 2026-09-01 (won't do):** offline episode
downloads for offline playback, and Web Push notifications for new
episodes — both real, substantial (days-to-weeks each) undertakings that
weren't what motivated this in the first place.
