# Backlog

Open work items and pending design decisions, kept here (rather than only in
Claude's per-machine memory) so they survive across computers. Last synced
2026-10-31.

---

## Open backlog items

### Miscellaneous open items

- **Revisit the category merge (next days, from 2026-10-21).** The mapping
  table (1c6a0807, Mappings tab on /admin/categories/merge, 34 old Apple
  names seeded) went to prod 2026-10-21, with the stray merges there. Check
  whether old names still come back while the monthly metadata refresh runs
  through the podcasts (rotation until about 2026-11-21), and merge any new
  strays (sub before parent, so the mapping gets the name feeds use).

- **#496 Parser saves unknown language codes without a name (found
  2026-10-31).** `Pan.Parser.Language.get_or_insert/1` inserts every
  language code it doesn't know yet with a UUID as `name` and `"_ is
  missing"` as `emoji`; they show up as "_ is missing <uuid>" in "Languages
  I speak" on Update Profile. 34 such rows came in since 2026-09-01 and were
  named by hand on prod 2026-10-31 (console script). New ones will keep
  coming until the parser handles unknown codes differently; how is open.

- **#498 Stale `podcasts.subscriptions_count` (found 2026-10-31).** The
  Subscribe button shows the stored count, which is only recomputed on a
  subscribe toggle (`Podcast.update_subscriptions_count/1`). On dev, podcast
  104 showed 19 while it has 16 subscriptions; after one toggle it was right.
  Counts go stale when subscriptions disappear another way (e.g. user or
  podcast deletion, merges). Same question for the like and follow counts.

- **#502 Persona claim mail doesn't escape user data (found 2026-10-31).**
  `Pan.Email.confirm_persona_claim_link_html_email/3` puts `user.name`,
  `user.username` and `user.email` into the HTML body unescaped, so a user
  can inject HTML into a mail sent to a third party (the persona's email
  address). `confirm_podcast_claim_link_html_email/4` right below escapes
  with `Phoenix.HTML.html_escape/1`; check the other mails in `lib/email.ex`
  too.

- **Listener and Podcaster Manual: review findings (2026-11-03).** In the
  qed site, `pages/manuals/listener-manual.md` and `podcaster-manual.md`,
  checked against the app.
  - #521 Both intros link only to each other; add the Moderator and Curator
    Manual (or the `/manuals/` overview).
  - Listener Manual:
    - #522 Search example link broken: `/search?search[searchstring]=Stefan`
      lands on "We don't know a persona with that name"; search URLs are
      `/search/<index>/<term>` now.
    - #523 "Top 5 Liked Podcasts": the start page shows the top 10.
    - #524 "several symbols and a search field" in the sidebar: it is a text
      menu now. Communities is missing from the manual entirely; Latest
      Recommendations, New Podcasts/Episodes, Podcasters, Users and Manuals
      aren't described as menu entries.
    - #525 Theme toggle (light / system / dark) not mentioned.
    - #526 Personal menu list lacks My Moderations and My Curations (only
      for moderators/curators, a pointer to their manuals).
    - #527 Small text errors: "categorie", "the  title", "non-documentation
      pages" (from when the docs were part of the app).
  - Podcaster Manual:
    - #528 Podcast ownership not described: **Claim this podcast** on the
      podcast page (confirmation link to the feed's owner address),
      **Podcasts I manage** on My Podcasts, automatic assignment by owner
      email.
    - #529 **Check feed** (feed report with probes, for owners) not
      described.
    - #530 API "all endpoints are available without throttling" is wrong:
      `trigger_episode_update` answers 429 within 5 minutes of the last
      manual update of a podcast.
    - #531 Metadata Update: the once-every-5-minutes limit isn't mentioned.
    - #532 Dated passages: "no iTunes account", "Stefan held a talk at the
      last subscribe", the Podlove Publisher tip with GitHub issue 939.
    - #533 General Tips could recommend the `podcast:person` tag for
      contributors (the parser reads it).
    - #534 Removal requests go to stefan@, the new manuals use sonja@:
      which one?
  - Missing screenshots (demo data on dev is gone after a restore, recipe in
    Claude's memory; or shots from prod):
    - #535 Listener: start page, sidebar/categories, search results, podcast
      page with like/follow/subscribe, My Podcasts, My Data, sign up.
    - #536 Podcaster: QR code / subscribe button, persona search, Claim this
      podcast and Check feed (with #528/#529).

- **#516 LiveView test warning: form without id (found 2026-11-01).** The
  standards form (`phx-change="select_standards"`, check feed page) has no
  `id`, so `test/pan_web/live/check_feed_access_test.exs:122` warns
  "Detected a form with phx-change but missing id". Without an id LiveView
  can't restore the form after a reconnect. Fix: give the form an id.
