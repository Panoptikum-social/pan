**Hard rule from the user: I am never allowed to do parallel requests.** Outbound HTTP requests always run sequentially, one at a time. That rules out Task.async_stream with max_concurrency > 1, parallel Task.async calls, and concurrent fetch pools.

On 2026-10-02 I made the deprecated-podcasts page probe 10 podcasts concurrently (988367a4). After that, every probe on prod hit the 10 s deadline. On 2026-10-03, f75fa290 switched to `max_concurrency: 1` and kept the per-probe deadline. The user confirmed on prod that the problem is gone.

**Why:** parallel requests from prod trigger blocking (confirmed by the sequential fix working). Prod DNS has had no problems in 15 years, so the user rejected my DNS-stall theory.

**How to apply:** bound outbound fetches with per-request deadlines, never with concurrency. Don't propose parallelizing as a speed-up. Don't suspect prod DNS or resolver problems. See [verify-before-theorizing](verify-before-theorizing.md).
