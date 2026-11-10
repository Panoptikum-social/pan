`PanWeb.Feed.clean_and_best_matching/1` (legacy, 2021) retries an unknown url with ever shorter prefixes and a `LIMIT 1` without ORDER BY, so `anchor.fm/s/528cb318/podcast/rss` ended at `anchor.fm/s` and matched an arbitrary anchor.fm podcast (dev: "On the NBA Beat" 37910; prod: a different one, row order differs). The moderation "add feed" acted on that match and linked the wrong podcast to the community instead of importing the new one (2026-10-01, fixed and deployed in 14fc5576).

Now: moderation uses `Feed.clean_and_direct_matching/1` (feed url, alternate feed or website only, no stripping). The admin feed backlog keeps the loose match, it's only a hint there.

**Why:** shared hosts (anchor.fm, podbean, megaphone, spreaker) make prefix matching meaningless.
**How to apply:** never use `clean_and_best_matching` where code acts on the result without a human checking it. To find out which podcast a past loose match hit on prod, run the old function with the same url in the prod remote console; it repeats the same query (user confirmed this worked). Older moderator adds from shared hosts on prod may have linked wrong podcasts, never audited.
