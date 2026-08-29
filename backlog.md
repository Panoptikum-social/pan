# Backlog

Open work items and pending design decisions, kept here (rather than only in
Claude's per-machine memory) so they survive across computers. Last synced
2026-08-29.

---

## Open backlog items

### Manual "update from feed" ignores a feed's `new-feed-url` migration signal (found 2026-08-29)
`Pan.Parser.Analyzer` parses `<new-feed-url>` / `<itunes:new-feed-url>` into a
top-level `new_feed_url` map key (`lib/pan/parser/analyzer.ex:25-27`) — the
feed's own "I've permanently moved" signal. The periodic background updater
(`Pan.Updater.RssFeed` → `Persistor.delta_import/2`) acts on it: it's
specifically preserved through the filtered/delta parse by
`Pan.Updater.Filter.only_new_items_and_new_feed_url/2`
(`lib/pan/updater/filter.ex`), and `delta_import/2` explicitly calls
`Feed.update_with_redirect_target(podcast.id, map[:new_feed_url])`
(`lib/pan/parser/persistor.ex:68`).

The manual/full "update from feed" path
(`Pan.Parser.Podcast.update_from_feed/1` → `Persistor.update_from_feed/2`,
triggered by the moderator button, the API endpoint, and the
like/follow/subscribe auto-update) parses the same `new_feed_url` key into its
`podcast_map`, but never reads it — and since `new_feed_url` isn't a
`PanWeb.Podcast` schema field, `Ecto.Changeset.cast/3` silently filters it out
with no error and no effect (`lib/pan/parser/persistor.ex:78-141`). That path
only follows redirects detected a different way — by comparing the feed's own
`<atom:link rel="self">` against the stored `self_link_url`
(`lib/pan/parser/persistor.ex:121-123`). So a feed that publishes
`<itunes:new-feed-url>` only gets migrated via the periodic job; a manually
triggered "update from feed" silently no-ops on that signal.

**Fix when picked up:** in `Persistor.update_from_feed/2`, after computing
`feed_map`/before or alongside the existing `feed.self_link_url !=
feed_map[:self_link_url]` check, also call
`Feed.update_with_redirect_target(podcast.id, map[:new_feed_url])` when
`map[:new_feed_url]` is present — mirroring what `delta_import/2` already
does. Note `update_from_feed/2`'s `podcast` var gets reassigned partway
through (`{:ok, podcast} = PanWeb.Podcast.changeset(...) |> Repo.update()`),
so use `podcast.id`, not a stale binding. No filter step is needed here (unlike
the delta path) since `Pan.Parser.RssFeed.import_to_map/2` already parses the
full feed body without the delta/filtered reduction, so `new_feed_url` is
already present in `map` when set.

### Move qa/prod secrets to `config/runtime.exs`
There's no `config/runtime.exs` at all today — the full config chain
(`config.exs` → `qa.exs`/`prod.exs` → `qa.secret.exs`/`prod.secret.exs`) is
compile-time only, so secrets (DB password, `PanWeb.Endpoint` `secret_key_base`,
mailer creds) end up baked in plaintext inside the release/image itself. Standard
modern Phoenix (1.6+) generates `runtime.exs` by default; this app predates/diverges
from that.

**Fix when picked up:** add `config/runtime.exs`, move secret-bearing keys out of
`qa.secret.exs`/`prod.secret.exs` into `System.get_env/1` reads gated by
`config_env()`, update `docker-compose.yml` to pass them via `environment:` instead
of baking them into the build context, update `DOCKER.md` accordingly. Touches both
the QA Docker flow and the bare-metal prod deploy — test both.
