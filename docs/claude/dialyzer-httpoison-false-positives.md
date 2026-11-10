ElixirLS Dialyzer reports six warnings in `lib/pan/feed_probe.ex` (`first_bytes/2`, `read_first/7`, `close/1`, lines ~193–252 as of 2026-10-19): "pattern can never match", "HTTPoison.stream_next will never return", "is_pid(_id :: reference()) can never succeed", etc.

They are false positives: HTTPoison 3.0.0 still types the async ids as `reference` (`HTTPoison.AsyncResponse.t`), but on hackney 4.8 the id is a connection pid (hackney's `stream_next/1` has `when is_pid`). Verified on dev 2026-10-19: a streaming request returns a pid; the audio probes work on prod. Dialyzer then treats the whole receive loop as unreachable.

**Why:** user decided 2026-10-19 to leave them (#253); no upstream report (#254) and no ignore file (#255). Not a stale `.elixir_ls/` build, deleting it won't help.
**How to apply:** don't chase these warnings or "fix" the pid guard; they vanish only if HTTPoison corrects its typespec. Related: [httpoison-req-migration](httpoison-req-migration.md), [stale-ide-diagnostics](stale-ide-diagnostics.md).
