# Backlog

Open work items and pending design decisions, kept here (rather than only in
Claude's per-machine memory) so they survive across computers. Last synced
2026-11-05.

---

## Open backlog items

### Project #4: multilingual Panoptikum (started 2026-11-05)

English and German; curations, moderations and frontend are done (decisions
and code map in Claude's memory, project_multilingual). Open:

- #582 Translated data, the last step of phase 3:
  - #566/#567 category titles and language names in a JSONB map column on
    the record, keyed by locale (e.g. `%{"de" => "..."}`).
  - #585 German category titles get entered on a small admin page
    (English UI) listing categories with a German field each.
  - #571 gig/engagement roles: gettext lookup, falling back to the stored
    value.
  - #569 search finds categories by their translated titles too.
- Deploy: prod needs the users.locale migration and an assets build
  (language switcher, Podlove language).
- #586 Links to the qed site (About, Manuals, Privacy, ...) stay English;
  once those pages are translated, the links get fixed.
- #563 Check whether the existing users_languages table can serve as a
  default for the interface language.
- #562 Maybe Italian, French and Spanish once everything is finished (far
  on the horizon).
- #590 Cleanup: the persona delegation/redirection links on My Profile
  (_personas.html.heex: toggle_delegation, redirect, cancel_redirect) are
  GET links that change data; the POST + "Are you sure?" rule (#449)
  says POST. User decides later.
- #576 Cleanup: the moderation edit pages (EditPodcast, EditEpisode,
  EditFeed) use `:admin_live_view` and override its English with
  `on_mount PanWeb.Locale`. Moving them to `:moderation_live_view` would
  be cleaner but changes padding/width; user decides later.

### Miscellaneous open items

- **Revisit the category merge (next days, from 2026-10-21).** The mapping
  table (1c6a0807, Mappings tab on /admin/categories/merge, 34 old Apple
  names seeded) went to prod 2026-10-21, with the stray merges there. Check
  whether old names still come back while the monthly metadata refresh runs
  through the podcasts (rotation until about 2026-11-21), and merge any new
  strays (sub before parent, so the mapping gets the name feeds use).
