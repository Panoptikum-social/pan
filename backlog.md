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

- **npm audit advisories in the build tools (found 2026-10-19).** `braces`
  3.0.3 (high, via `@tailwindcss/cli` → `@parcel/watcher` → `micromatch`) and
  `postcss-selector-parser` 6.0.10 (moderate, via `@tailwindcss/typography`
  0.5.20). Both are denial of service on hostile input and run only at build
  time on our own templates and CSS, never in the browser. `npm audit fix
  --force` would downgrade typography to 0.5.4, so not that. Check again
  after the next `@tailwindcss/cli` / `@tailwindcss/typography` releases
  (`cd assets && npm audit`).

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

- **Dark-mode screenshots for the Listener and Podcaster Manual (started
  2026-10-31).** The manuals in the qed site
  (`/daten/DATA/rust/sites/blog.panoptikum.social`, `pages/manuals/`) still
  show 2017 screenshots. Decisions: new file names, only the manuals point to
  them, the old 2016–2018 blog posts keep their images (#486); taken on the
  dev server with headless Chrome in Mocha (#487); screenshots of removed or
  changed features get a list for Stefan to decide (#488); a demo user, not a
  real account (#489). Scripts and the 10 finished images are in
  `/daten/DATA/phoenix/pan-assets/manual-screenshots/` (`npm install` there
  first; `lib.mjs` logs in with a token from `PanWeb.Auth.sign_token(:link,
  user_id)`).
  - Done: user menu, My Profile, Update Profile, persona with and without
    email address (claim panels), claim warning, Metadata Update, retired
    podcast notice, claiming a contribution (before/after).
  - First, after each dev DB restore: recreate the demo data — user `demo`
    ("Demo Podcaster", demo@example.com, podcaster, email verified; its
    first login creates persona "Demo Podcaster"), personas "D. Podcaster"
    (no email), "Demo Co-Host" (demo-cohost@example.com) and "Demo und
    Co-Host" with gigs and engagements on Aua-uff-Code! (podcast 104, five
    latest episodes); claim D. Podcaster, claim Demo Co-Host by email (grant
    link from /dev/mailbox), claim a contribution on episode 6206480.
  - To do: claim request email and "email sent" page, Edit persona before
    and after (PID `demo-podcaster`, image, description), public persona
    page, delegations (D. Podcaster and Demo Co-Host → Demo Podcaster),
    listener screenshots, the #488 list (Podlove 5.7.4 dialogs,
    Twitter/Facebook sharing, mail client, withdraw tooltip), then import
    the images and update the two manual pages through the qed MCP server.
  - Persona-editing shots need 16d5e143 (#492, #493), committed, on dev.
