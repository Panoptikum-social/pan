# Backlog

Open work items and pending design decisions, kept here (rather than only in
Claude's per-machine memory) so they survive across computers. Last synced
2026-09-26.

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
- Test coverage is largely done: `Helpers` (`test/pan/parser/helpers_test.exs`) and
  `Analyzer`/`Iterator` (`test/pan/parser/feed_parsing_test.exs`, ~50 tests) since
  2026-09-21. Only the rarer tag aliases are still uncovered. Unknown tags are
  skipped silently on purpose (no ignore lists, no logging).

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

**Status:** the check is live in prod as `PanWeb.Live.Podcast.CheckFeed`. The
rule engine is the separate Hex library `check_my_feed` (github.com/Panoptikum-social/check-my-feed,
sibling directory `../check-my-feed`, mirrored privately on code.informatom.com).
A new library release: bump the version, `mix hex.publish` (2FA), then update
Pan's requirement and lock.

**Decisions still in force:** the library parses raw feed XML itself (no Pan
parser code, since Pan's fix-ups would hide what the tool must report), takes an
XML string and does no fetching; Pan downloads a fresh copy per check via
`Download.get/2` (SSRF guard applies). Only for podcasts listed in Panoptikum.

**Still open, later (agreed):** Podcasting 2.0 rules, active probing (below), the
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
- A rule counts as passed when it had nothing to check (e.g. the enclosure
  rule on a feed with no episodes); consider hiding those from "Passed".
- Library tests print an xmerl `[error] fatal` log line for the broken-XML
  test (Pan silences that via `Pan.LoggerFilters`, the library doesn't).
- Findings only cover the first feed of a podcast (`Feed.get_by_podcast_id/1`).

---

### Project #3: community pads (found 2026-10-09)
A pad is basically a markdown field that several users of a community can
edit synchronously.

**User of the community** (decided 2026-10-09): a user who follows the
community, i.e. has a row in `follows` with that `community_id` (the existing
follow button). No separate community subscription.

**Decided (2026-10-09):**
- Sync: CodeMirror 6 with `y-codemirror.next` in the browser, `y_ex` (Yjs
  CRDT, Rust NIF) on the server, over a Phoenix Channel, one process per open
  pad. Rejected: Milkdown, a lock (one editor at a time), Quill, and binding
  Yjs to the OverType textarea by hand.
- Split view: editor left, preview right. The preview is rendered on the
  server by the pad process with the existing `markdown/1` helper (MDEx +
  `MarkdownWithoutImages`), debounced (~300 ms) and broadcast to everyone
  viewing, so it matches the final display.
- Mobile: Edit/Preview tabs below a breakpoint, two columns above it.
- Rough scroll sync between editor and preview, by scroll percentage.
- Existing markdown fields (curations, persona long descriptions) stay on
  OverType.
- Storage: keep both the Yjs state (for editing) and a markdown copy (for
  display and search). There won't be many pads.
- Several pads per community, each with a title that is unique within its
  community and serves as the key.
- Permissions, for the beginning: every follower of the community can read
  and edit its pads; visitors (and non-followers) don't see them. Only
  moderators of that particular community create pads. Being a moderator
  gives no read/edit access without following the community.
- A moderator of the community can set a pad to read only and back to
  editable. Read only freezes the pad for everybody, moderators included.
- Snapshots (markdown text only):
  - automatic, after about 5 minutes without edits or when the last person
    leaves the pad, skipped if nothing changed;
  - a "Save version" button with an optional note;
  - restoring replaces the text as a normal edit, so people editing see it
    live and a restore can itself be undone by restoring again;
  - all snapshots are kept.

---

### Manticore sync: code paths never run yet (found 2026-10-01)
The Manticore index sync overhaul (2026-10-01) is deployed, but these paths
have only been compiled, never exercised:
- category merge
- persona merge and delete
- the API persona endpoints
- the persona thumbnail job
- the admin orphan button (`Pan.Search.delete_orphans/2`)

