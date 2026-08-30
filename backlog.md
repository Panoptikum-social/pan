# Backlog

Open work items and pending design decisions, kept here (rather than only in
Claude's per-machine memory) so they survive across computers. Last synced
2026-08-30.

---

## Open backlog items

### `/podcasts/deprecated` deletion mechanism is too drastic (found 2026-08-30)
Restored the missing "Deprecated" button on the podcast admin index (it had
lost its link but the route/controller/template/model logic — `PodcastController.deprecated/2` →
`Podcast.get_deprecated/1` in `lib/pan_web/models/podcast.ex` — were all
still intact). Reading the mechanism closely to review it surfaced six
concerns, all still open:

1. **One HTTP request, one moment in time, decides forever.**
   `probe_deprecated/1` makes a single GET, no retry, and
   `process_deprecated/1` immediately acts on it. For a `Repo.delete!`
   (episodes, chapters, likes, recommendations — everything cascades),
   that's a lot of weight on one data point.

2. **Several "dead" codes are actually transient.** `@dead_status_codes`
   includes `500`, `503`, `:timeout`, `:connect_timeout`, `"TLS alert"`,
   `400`, `409` — these are frequently temporary (a server hiccup, rate
   limiting, a maintenance window, a momentary network blip), not reliable
   "this feed is gone" signals. A perfectly healthy, currently-publishing
   podcast can get permanently deleted because its host returned a 503 at
   the exact second an admin happened to load this page.

3. **Doesn't reuse the app's own hardened HTTP layer.** `Pan.Parser.Download`
   has a TLS 1.3→1.2 fallback retry for servers with handshake quirks, and a
   rescue around hackney's garbled-response crash (both from this same
   session's error-triage work). `probe_deprecated/1` calls raw
   `HTTPoison.get/3` directly, bypassing both — and explicitly buckets
   `"TLS alert"` as *death* rather than retrying with TLS 1.2 the way the
   regular update path now does. The code deciding "permanently delete
   this" is less resilient to exactly this class of quirk than the code
   that just marks something stale-for-now.

4. **Checks the wrong signal.** It probes the newest episode's *audio
   enclosure* URL, not the podcast's actual feed (`self_link_url`) — which
   is what the regular update path checks. Many hosts serve enclosures via
   short-lived/signed CDN links that legitimately expire independent of
   whether the show is still active. A fully healthy, currently-publishing
   podcast can fail this probe purely because one old episode's file link
   rotated.

5. **The action fires as a side effect of a page load.** Visiting
   `/podcasts/deprecated` — semantically "show me the list" — *is* the
   action. Probing and deleting/unretiring happen inside `get_deprecated/1`
   before the template ever renders; there's no preview-then-confirm step.
   The template's Delete/Unretire buttons (`deprecated.html.heex`) are dead
   code for both automated outcomes (their conditions explicitly exclude
   `"deleted"`/`"unretired"`/`200` — exactly what auto-processing already
   turned matching rows into), left over from an older manual-confirmation
   design that a later "automatic deletion" commit didn't fully update.

6. **`unretire/1` doesn't reset `failure_count`.** Compare
   `unpause_and_reset_failure_count/1` (the normal recovery path, in
   `lib/pan/updater/podcast.ex`), which resets `update_paused`, `retired`,
   *and* `failure_count` together. `unretire/1` (in
   `lib/pan_web/models/podcast.ex`) only clears `retired` — `failure_count`
   stays at 9 (the exact threshold that caused retirement in the first
   place). The very next single failure on a just-resurrected podcast
   immediately re-triggers retirement, rather than giving it a fresh run at
   the normal 10-strike allowance.

**Fix direction when picked up:** probe `self_link_url` through
`Download.get/1` instead of the enclosure via raw `HTTPoison`; shrink
`@dead_status_codes` to genuinely permanent signals (`404`, `410`,
`:nxdomain`) and leave everything else "inconclusive — stays retired, try
again later" instead of auto-deleting; fix `unretire/1` to reset
`failure_count` too. Whether to also reintroduce a real preview/confirm
step (vs. today's auto-act-on-page-load) is a product decision, not just a
code fix — worth deciding explicitly rather than assuming.

**Note:** user does not agree with all 6 points as stated above (didn't say
which) — this is Claude's read of the code, not a jointly agreed spec.
Re-discuss which concerns the user actually wants acted on before
implementing anything here, rather than fixing all six as written.
