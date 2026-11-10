The fallback clause in `Pan.Parser.Download.download/2` that only calls `Logger.error("status_code unknown ...")` (and so returns `:ok`) is deliberate. It is how the user finds new status codes, which then get added to `@error_map` and the guard list.

**Why:** The user wants new codes to show up in the error logs. They rejected my 2026-09-25 suggestion to return an `{:error, _}` tuple there.

They know the `:ok` return crashes `ImportStalePodcasts` with a `WithClauseError` (in `Pan.Updater.Podcast.import_new_episodes`). They declined the "log + return `{:error, _}`" fix a second time on 2026-09-25, so that crash is accepted.

**How to apply:** When a new "status_code unknown N" shows up, just add N to `@error_map` and the guard list. Don't flag the `:ok` return as a bug.
