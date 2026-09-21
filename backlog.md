# Backlog

Open work items and pending design decisions, kept here (rather than only in
Claude's per-machine memory) so they survive across computers. Last synced
2026-09-21.

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

**Status:** phase C (any logged-in user, "Check feed" button on the podcast
page) is live in prod as `PanWeb.Live.Podcast.CheckFeed`. The rule engine is the
separate Hex library `check_my_feed` (github.com/Panoptikum-social/check-my-feed,
sibling directory `../check-my-feed`, mirrored privately on code.informatom.com).
A new library release: bump the version, `mix hex.publish` (2FA), then update
Pan's requirement and lock.

**Decisions still in force:** the library parses raw feed XML itself (no Pan
parser code, since Pan's fix-ups would hide what the tool must report), takes an
XML string and does no fetching; Pan downloads a fresh copy per check via
`Download.get/2` (SSRF guard applies). Only for podcasts listed in Panoptikum.

**Still open, in order:**
1. *Overhaul user verification* (next item below) comes first.
2. *Access phase B:* real podcast claiming (proof of feed control, e.g. token
   in the feed or mail to the `itunes:owner` address). No user-to-podcast
   ownership exists today, only personas can be claimed. (Access phase A, gig
   based, was skipped 2026-09-21.)
3. *Later, agreed:* Podcasting 2.0 rules, active probing (below), the
   info-level "Panoptikum tolerates this" report (the ~70 date formats, entity
   fixups etc. in `lib/pan/parser/helpers.ex`), JSON API (maybe never).

**Active probing (later), collected checklist:** needs downloads of artwork and
media, so it is not possible from feed text. Artwork: size 1400-3000 px, square,
no alpha channel, real file type vs. extension, 72 dpi, RGB. Enclosures: HEAD
request (reachable, length matches). Audio for RSS: MP3 or AAC (AAC in MP4
preferred), bit rate/sample rate by channel count, loudness around -16 LKFS,
true peak below -1 dBFS. WAV/FLAC requirements are for Connect subscriber
uploads only.

**Small known issues:**
- Some feed servers answer 403 to Panoptikum's user agent, so the page reports
  a failure although the feed is fine (2 of 12 sampled feeds).
- A rule counts as passed when it had nothing to check (e.g. the enclosure
  rule on a feed with no episodes); consider hiding those from "Passed".
- Library tests print an xmerl `[error] fatal` log line for the broken-XML
  test (Pan silences that via `Pan.LoggerFilters`, the library doesn't).
- Findings only cover the first feed of a podcast (`Feed.get_by_podcast_id/1`).

---

### Overhaul user verification (added 2026-09-21)

Two steps, in this order:

1. *Rename "email confirmation" to "email verification"* everywhere, including
   the database: `users.email_confirmed` becomes `email_verified` (migration),
   plus the schema/changesets (`lib/pan_web/models/user.ex`), API auth and
   session controllers, `UserView`/JSON download view, `maintenance_controller`,
   persona show/frontend controller checks, `my_data` template, the
   `confirm_email` route/action/`email_confirmed.html` template, and
   `Pan.Email.email_confirmation_link_html_email` (incl. subject line). Keep
   `password_confirmation` untouched, that is a different concept.
2. *Replace the current implementation with a more standard / established
   one.* Which approach is not decided yet.

### PWA: asset caching + lock-screen media controls (found 2026-09-01)
Tier 1 (manifest, icons, service worker, installable shortcut) is done. What
remains, deliberately scoped to what is useful for a podcast site without
hitting LiveView's ceiling (pages need a live WebSocket, so they cannot work
offline):

- Service-worker asset caching (CSS/JS/icons) so repeat loads are instant, with
  a friendly offline fallback instead of a browser error page.
- Media Session API integration: lock-screen/notification playback controls
  (play/pause/skip, artwork), wired to the Podlove player's playback events
  (`registerExternalEvents` in `assets/js/podlove_player.js`). Frontend only.
