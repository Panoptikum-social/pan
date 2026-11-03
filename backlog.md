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

- **Moderator and Curator Manual: two held-back screenshots (2026-10-31).**
  The manuals are published with 15 screenshots. Open for Stefan to
  decide:
  - #514 Curators page ("Curators of my communities"): the shot shows the
    usernames of all real Wisspod curators (informatom, pikarl, rupi42ai,
    susticle, tomkalei). Use it, or leave the Curators section without one.
  - #515 API errors page: empty on dev (no errors in the last 24 hours).
    a) no picture, b) on dev move a few real error rows into the last 24
    hours and take the shot, c) take it on prod.
  Demo setup on dev (moderator + curator of Wisspod, example curations,
  "Manual demo pad") is gone after a dev restore; recipe in Claude's memory.

- **General manual improvements of the user and podcaster manual (added
  2026-11-01).** In the qed site, `pages/manuals/`.

- **#516 LiveView test warning: form without id (found 2026-11-01).** The
  standards form (`phx-change="select_standards"`, check feed page) has no
  `id`, so `test/pan_web/live/check_feed_access_test.exs:122` warns
  "Detected a form with phx-change but missing id". Without an id LiveView
  can't restore the form after a reconnect. Fix: give the form an id.
- **#520 Blog links without trailing slash (found 2026-11-03).** The qed
  blog answers `/privacy`, `/complaints` etc. with a 301 to the same path
  with a slash. Sidebar and footer are fixed; still without slash:
  `privacy` in `lib/pan_web/live/home.ex` (cookie notice) and
  `lib/pan_web/templates/user/forgot_password.html.heex`, `complaints` in
  the three `recommendation_list.ex` LiveViews (chapter, episode, podcast).
  Fix: add the slash.
