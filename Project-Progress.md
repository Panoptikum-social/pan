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
- Panoptikum can now be installed as an app on your phone or desktop; previously visited pages keep working offline, and the episode you're playing shows its podcast artwork in your device's media controls/lock screen.
- New "Remember me for 30 days" option on login, so you don't get logged out every time you come back.
- Logging in with a password now requires a verified email address; if yours isn't verified yet, a new page lets you resend the verification mail.
- Accounts that have been inactive for a long time, or whose email was never verified, now get a warning mail with a one-click login link before being marked for deletion; logging in (or following any emailed link) clears the mark.
- Fixed a crash on podcast/community/persona pages caused by malformed website or contact links coming from feed data — these are now shown as plain text instead of breaking the page.

# News for Podcasters

- Podcast metadata (title, description, artwork, categories, contributors, etc.) is now refreshed automatically about once a month, even if nobody manually triggers an update.
- Much more robust feed parsing: handles more date/timestamp formats, missing enclosure URLs, invalid UTF-8, oversized fields, more HTTP/TLS quirks, stray DOCTYPE declarations and duplicate/misplaced `<?xml ...?>` headers, HTML entities in umlauts/ß, stray ampersands and non-breaking spaces, and empty contributor/name elements — feeds that used to fail on these now import cleanly instead of crashing the whole run.
- Redirect loops when fetching your feed are now capped and detected, instead of hanging or looping forever.
- Podcasts using the `<podcast:person>` tag now get contributors (hosts, guests, etc.) imported correctly; stale contributor roles are cleaned up automatically whenever your feed is re-parsed.
- Podcast artwork now gets refreshed together with the rest of your feed data, not just on request.
- Fixed podcast website links being incorrectly lowercased.
- More reliable background update jobs — hardened against crashes, against duplicate/overlapping update runs for the same podcast, and against certificate/TLS errors while fetching a feed; failed metadata updates are now logged with a failure counter instead of failing silently.
- Feed fetching is now protected against redirects to internal/private network addresses, with a stricter timeout, and monthly update checks are spread out with jitter instead of all firing at once.
- New "Check my feed" button on your podcast page runs Panoptikum's feed-compliance checker directly and shows the results (visible to you, admins and moderators).
- New: claim ownership of your podcast from `/my_podcasts` (matched by owner email, or via a confirmation mail) to manage it and use the feed checker; admins can also assign, reassign or unassign ownership.
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
- Admin/moderator grids now support select-all and deleting multiple rows at once.
- New admin page (`/admin/users/retention`) for data retention: combinable filters (unverified, never logged in, inactive 2+ years, marked, deletable), search, bulk mark/unmark and delete, and sending deletion-notice mails.
- New admin page (`/admin/podcasts/owners`) to assign, reassign or unassign podcast ownership; all changes are journaled.
- Admin/moderator rights are now re-checked against the database on every page load instead of only at login, so a revoked account loses access immediately.
