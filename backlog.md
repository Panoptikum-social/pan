# Backlog

Open work items and pending design decisions, kept here (rather than only in
Claude's per-machine memory) so they survive across computers. Last synced
2026-11-05.

---

## Open backlog items

### Project #4: multilingual Panoptikum (started 2026-11-05)

English and German; curations, moderations and frontend are done and
deployed (decisions and code map in Claude's memory, project_multilingual).
Open:

- #586 Links to the qed site (About, Manuals, Privacy, ...) stay English;
  once those pages are translated, the links get fixed.
- #600 German screenshots for the German manuals on the qed site (they
  show the English interface for now, #599).
- #601 German main menu on the qed site: the hand-made menu in site.toml
  has English titles, which qed shows in every language. Waits for
  per-language menu titles in qed (user fixes qed).
- #603 Outdated content on the qed start page (both languages): the site
  is described as built with Jekyll and jekyll-Octopod (it's qed now), and
  Twitter @panoptikumIO is given as contact (also on the Imprint).
- #562 Maybe Italian, French and Spanish once everything is finished (far
  on the horizon).

### Miscellaneous open items

- **Revisit the category merge (next days, from 2026-10-21).** The mapping
  table (1c6a0807, Mappings tab on /admin/categories/merge, 34 old Apple
  names seeded) went to prod 2026-10-21, with the stray merges there. Check
  whether old names still come back while the monthly metadata refresh runs
  through the podcasts (rotation until about 2026-11-21), and merge any new
  strays (sub before parent, so the mapping gets the name feeds use).
