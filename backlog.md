# Backlog

Open work items and pending design decisions, kept here (rather than only in
Claude's per-machine memory) so they survive across computers. Last synced
2026-08-30.

---

## Open backlog items

### Regular podcast-data update job (found 2026-08-30)
Podcast *metadata* (title, description, image, etc. — everything besides episodes)
is currently only refreshed on request (moderator "update from feed" button, the API
endpoint, like/follow/subscribe auto-update) — there's no regular background job
that keeps it current on its own. Want a real update job for this.

**Confirmed 2026-08-30:** `Pan.Job.ImportStalePodcasts` (already running in
`config/prod.exs`/`config/qa.exs`) only covers *episode* data — it does not touch
podcast-level metadata. So this is a real gap, not overlap with an existing job.

**Requirement:** make sure whatever job gets built doesn't introduce unwanted side
effects — not yet specified in detail what those side-effect risks are, needs
discussion when this is picked up.
