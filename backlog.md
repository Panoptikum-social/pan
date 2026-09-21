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

**Status:** the check is live in prod as `PanWeb.Live.Podcast.CheckFeed`. The
rule engine is the separate Hex library `check_my_feed` (github.com/Panoptikum-social/check-my-feed,
sibling directory `../check-my-feed`, mirrored privately on code.informatom.com).
A new library release: bump the version, `mix hex.publish` (2FA), then update
Pan's requirement and lock.

**Decisions still in force:** the library parses raw feed XML itself (no Pan
parser code, since Pan's fix-ups would hide what the tool must report), takes an
XML string and does no fetching; Pan downloads a fresh copy per check via
`Download.get/2` (SSRF guard applies). Only for podcasts listed in Panoptikum.

**Still open, in order:**
1. *Access phase B:* real podcast claiming (proof of feed control, e.g. token
   in the feed or mail to the `itunes:owner` address). No user-to-podcast
   ownership exists today, only personas can be claimed. (Access phase A, gig
   based, was skipped 2026-09-21.)
2. *Later, agreed:* Podcasting 2.0 rules, active probing (below), the
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

### User retention: open follow-ups
- *Automatic notice job deployed (2026-09-21):*
  `Pan.Job.SendRetentionNotices` (prod only) sends one notice every 5 minutes to
  the lowest-id unmarked user who is either unverified for more than 30 days or
  verified without a login for 2 years (signup date counts if never logged in);
  marking happens as with the manual "Send notice". A failing address is skipped
  until the next restart. Deleting stays manual.
- *Account deletion keeps more than the account:* personas stay including an
  email address stored on them (persona.user_id is left dangling), invoices stay
  with user_id set to null. The privacy page says so. Not changed in code.
- *No retention period is stated* for the `bounce@` mailbox and for Journal
  entries of failed mail deliveries (recipient + subject).
- *Suspect email addresses found 2026-09-21 in the dev copy of the users table*
  (a DNS check of all domains): 64 users on 58 nonexistent domains (21 of them
  verified, many look like bots), 3 addresses with whitespace or a CRLF (ids
  1414, 1416, 4527), a few disposable and placeholder addresses. The registration
  does not trim whitespace from the email. All 864 unverified users have never
  logged in (490 signed up in 2019). Nothing was changed or deleted; a CSV of the
  suspects went to the user (not in a repo).

### Bounce handling for outgoing mail (added 2026-09-21; only the reader and actions on bounces are open)
Problem: a nonexistent address goes unnoticed. The app only talks to our relay
(`box.mittenin.at`, Mail-in-a-Box/Postfix), which reports failures later as a
bounce mail to the envelope sender, and all 7 `Pan.Mailer.deliver()` calls ignore
the return value.

**Mail server side is ready, no server change needed (tested 2026-09-21):**
- `bounces@panoptikum.social` is an alias forwarding to the `bounce@panoptikum.social`
  mailbox, with `robot@informatom.com` (the app's SMTP login) as permitted sender.
  Without that, the relay refuses the envelope sender: `553 5.7.1 Sender address
  rejected: not owned by user robot@informatom.com`.
- Swoosh's SMTP adapter uses the email's `Sender` header as the SMTP envelope
  sender (else the From address), so `Sender: bounces@panoptikum.social` on an
  email is all the app would need; From stays `noreply@panoptikum.social`.
- Tested with swaks (login robot@, `MAIL FROM:<bounces@...>`, From header
  noreply@): accepted, and the bounce arrived in `bounce@` after about 3 seconds.

**What a bounce looks like (both tests):** standard delivery report with
`Final-Recipient`, `Action: failed`, `Status`, `Diagnostic-Code`, and the complete
original message attached (headers and body, our headers such as Message-Id come
back unchanged; the Postfix queue id is in the `Received` line and matches the
"queued as ..." receipt that Swoosh's SMTP adapter returns from `deliver()`).
- nonexistent mailbox at a real provider (gmail): `Status: 5.1.1`.
- nonexistent domain: `Status: 5.4.4`, bounced at once by Postfix (permanent, not
  retried for days; retrying only applies to temporary failures, not tested).

**Ways to tie a bounce to an account (options, not decided):** the failing
address in `Final-Recipient` (lookup by email), a marker header of ours in the
original (untested with a custom header), or the queue id from the receipt.

**Which statuses would mean "address is bad" (suggestion):** `5.1.1`, `5.1.2`,
`5.4.4`. Not `5.2.x` (mailbox full) or `5.7.x` (rejected as spam/policy), and
ignore `4.x.x` / `Action: delayed`.

**Current state:** bounces already arrive in `bounce@` (`Pan.Mailer.deliver/2`
sets the `Sender` header and logs the queue id). A reader for the mailbox and
any action on bounces are still open (decide after seeing real bounces).

**Notes:**
- A bounce contains the original mail, so for verification and login-link mails
  it contains a link that is a login token valid for 1 hour (30 days for the
  retention notice); treat the
  `bounce@` mailbox as sensitive and handle those links carefully in any reader.
- Using `accounts@` as a real mailbox/From was considered and advised against
  (replies and spam); VERP-style per-mail addresses are not needed so far and
  the address format would be our own choice, not a standard.
- A permanently bouncing address could count towards marking an account (see
  the retention item above).
- Open: what spam filtering the mail server applies to `bounce@`; whether to
  build a reader at all.

### PWA: asset caching (found 2026-09-01) — built 2026-09-21, awaiting prod test
Service worker (`priv/static/sw.js`) caches digested `/assets/*` and `/fonts/*`
cache-first, `/images/*` stale-while-revalidate, and falls back to
`priv/static/offline.html` when a page navigation fails. Untested in a browser
before deploy; bump `VERSION` in `sw.js` to reset all caches. Delete this item
once verified in prod.

Done 2026-09-21: lock-screen/notification media controls. The bundled Podlove
player (5.7.4) already implements the Media Session API (metadata, play/pause,
seek, previous/next); the only gap was the artwork, which was always the
placeholder. `PodlovePlayer` now passes the podcast's cached thumbnail as
poster. Verified on Linux Mint (media applet) and in prod.
