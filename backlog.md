# Backlog

Open work items and pending design decisions, kept here (rather than only in
Claude's per-machine memory) so they survive across computers. Last synced
2026-08-30.

---

## Open backlog items

### `/podcasts/deprecated` deletion mechanism fires as a side effect of a page load
Visiting `/podcasts/deprecated` — semantically "show me the list" — *is*
the action: `PodcastController.deprecated/2` → `Podcast.get_deprecated/1`
(`lib/pan_web/models/podcast.ex`) probes and deletes/unretires podcasts
before the template ever renders, with no preview-then-confirm step.

**Fix when picked up:** whether to reintroduce a real preview/confirm step
(vs. today's auto-act-on-page-load) is a product decision, not just a code
fix — worth deciding explicitly rather than assuming. The manual Delete/
Unretire buttons in `deprecated.html.heex` are still meaningful for the
"inconclusive" middle case (feed dead but episode still reachable, or vice
versa) but not for the two automated outcomes.
