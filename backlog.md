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
still intact). Reading the mechanism closely to review it surfaced several
concerns (numbered 1/2/4/5 — 3, 6, and 7 were fixed same day and are no
longer tracked here):

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

4. **Checks the wrong signal.** It probes the newest episode's *audio
   enclosure* URL, not the podcast's actual feed (`self_link_url`) — which
   is what the regular update path checks (now via the hardened
   `Download.get/1`, see point 3's fix below). Many hosts serve enclosures
   via short-lived/signed CDN links that legitimately expire independent of
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

**Fix direction when picked up:** probe `self_link_url` instead of the
enclosure (via the already-fixed `Download.get/1`); shrink
`@dead_status_codes` to genuinely permanent signals (`404`, `410`,
`:nxdomain`) and leave everything else "inconclusive — stays retired, try
again later" instead of auto-deleting. Whether to also reintroduce a real
preview/confirm step (vs. today's auto-act-on-page-load) is a product
decision, not just a code fix — worth deciding explicitly rather than
assuming.

**Note:** user does not agree with all of points 1/2/4/5 as stated above
(didn't say which) — those are Claude's read of the code, not a jointly
agreed spec. Re-discuss which of them the user actually wants acted on
before implementing.
