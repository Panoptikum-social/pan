Since commit 4435c94a (deployed + verified in prod 2026-09-30, Zeit für Wissenschaft, podcast 102 / feed 174):

- `alternate_feeds` is **history only**. A redirect target appearing there is NOT a loop — old URLs can legitimately become current again.
- "loop detected" = a target repeated within the redirect chain of **one** update (`visited_urls` in Pan.Updater.Podcast, Pan.Parser.Podcast, Pan.Parser.RssFeed.initial_import), plus the cap of 5 redirects.
- A differing `<atom:link rel="self">` is only stored as an alternate feed; the feed URL moves only on an HTTP 301/302/303/308 or `itunes:new-feed-url`. (Self links are often wrong — the uibk mp3 feed's self link points to its http ogg sibling.)
- Accepted trade-off: if new-feed-url points to a URL that redirects back, the feed switches between the two on each update, but every update still succeeds.

**Why:** the old history-based check plus following the self link left feeds permanently stuck on "loop detected" (http→https redirect to a URL that was in the history since 2022).

**How to apply:** when a feed reports "loop detected" or has URL-switching problems, trace the live redirect chain with curl and compare it to the stored self_link_url. Don't bring back the history-based loop check or self-link following.
