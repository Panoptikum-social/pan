# News for Users

- Complete visual refresh: the whole site was rebuilt on modern Phoenix LiveView components with a new Tailwind/DaisyUI look — cleaner pages, better color contrast, more readable buttons and forms everywhere.
- Noticeably faster page loads (switched the underlying web server, ~20% faster).
- New: browse podcasts organized into curated [Communities](/communities) (e.g. genre or regional groupings).
- Search can now be filtered by language, with a grouped language picker and a remembered preference.
- Various search bugs fixed (bad request escaping/headers that could cause missing or wrong results).
- You can now leave recommendations/comments on individual chapters, not just whole episodes or podcasts; "My Recommendations" also lists your chapter and episode recommendations now.
- Long podcast/episode titles and persona names no longer overflow buttons — they're truncated cleanly instead.
- Smoother infinite-scroll lists (episodes, podcasts, etc.), with several loading and spacing bugs fixed.
- Persona (person) profiles support markdown-formatted descriptions and a "rel=me" link (handy for verifying your Mastodon/fediverse account), plus various display bugs fixed.
- Fixed a login bug affecting expired sessions, and a bug in the "download my data" export.
- Sign-up/login form validation errors are now shown properly.
- The paid "Pro" plan has been discontinued — Panoptikum is now completely free to use.
- Fixed a batch of longstanding bugs found via a systematic review of production error logs.
- Empty notification ("flash") boxes no longer pop up by mistake.
- Added links to the Podcaster and Listener manuals, and to the API docs, in the site footer.

# News for Podcasters

- Podcast metadata (title, description, artwork, categories, contributors, etc.) is now refreshed automatically about once a month, even if nobody manually triggers an update.
- Much more robust feed parsing: handles more date/timestamp formats, missing enclosure URLs, invalid UTF-8, oversized fields, and more HTTP/TLS quirks without failing the whole import.
- Redirect loops when fetching your feed are now capped and detected, instead of hanging or looping forever.
- Podcasts using the `<podcast:person>` tag now get contributors (hosts, guests, etc.) imported correctly; stale contributor roles are cleaned up automatically whenever your feed is re-parsed.
- Podcast artwork now gets refreshed together with the rest of your feed data, not just on request.
- Fixed podcast website links being incorrectly lowercased.
- More reliable background update jobs — hardened against crashes and against duplicate/overlapping update runs for the same podcast.
- Various API fixes (response format, search, authentication).
- The paid "Pro" plan has been discontinued — every podcast now gets the same treatment, for free.

# News for Moderators

- New Communities feature: moderators can add podcasts straight into their community's feed and curate its categories themselves.
- The podcast-deprecation review page no longer deletes or un-retires podcasts as a side effect of loading the page — it only recommends an action, and an admin has to confirm it explicitly. Podcasts belonging to a Community are now always protected from deletion.
- New audit log (Journal) tracks moderation/admin actions, with a button to clear it.
- New admin action to reset runaway update intervals back down to at most a week.
- Clearer error messages when a podcast is paused or retired.
- Deleting a podcast or persona now automatically cleans up its search-index entry too.
- The moderation grid was rebuilt on the new component system along with the rest of the site, and gained a column showing when each podcast's metadata will next be refreshed.
