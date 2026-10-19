# Backlog

Open work items and pending design decisions, kept here (rather than only in
Claude's per-machine memory) so they survive across computers. Last synced
2026-10-19.

---

## Open backlog items

### Project #3: community pads (found 2026-10-09)
A pad is basically a markdown field that several users of a community can
edit synchronously.

**User of the community** (decided 2026-10-09): a user who follows the
community, i.e. has a row in `follows` with that `community_id` (the existing
follow button). No separate community subscription.

**Decided (2026-10-09):**
- Sync: CodeMirror 6 with `y-codemirror.next` in the browser, `y_ex` (Yjs
  CRDT, Rust NIF) on the server, over a Phoenix Channel, one process per open
  pad. Rejected: Milkdown, a lock (one editor at a time), Quill, and binding
  Yjs to the OverType textarea by hand.
- Split view: editor left, preview right. The preview is rendered on the
  server by the pad process with the existing `markdown/1` helper (MDEx +
  `MarkdownWithoutImages`), debounced (~300 ms) and broadcast to everyone
  viewing, so it matches the final display.
- Mobile: Edit/Preview tabs below a breakpoint, two columns above it.
- Rough scroll sync between editor and preview, by scroll percentage.
- Existing markdown fields (curations, persona long descriptions) stay on
  OverType.
- Storage: keep both the Yjs state (for editing) and a markdown copy (for
  display and search). There won't be many pads.
- Several pads per community, each with a title that is unique within its
  community and serves as the key.
- Permissions, for the beginning: every follower of the community can read
  and edit its pads; visitors (and non-followers) don't see them. Only
  moderators of that particular community create pads. Being a moderator
  gives no read/edit access without following the community.
- A moderator of the community can set a pad to read only and back to
  editable. Read only freezes the pad for everybody, moderators included.
- Snapshots (markdown text only):
  - automatic, after about 5 minutes without edits or when the last person
    leaves the pad, skipped if nothing changed;
  - a "Save version" button with an optional note;
  - restoring replaces the text as a normal edit, so people editing see it
    live and a restore can itself be undone by restoring again;
  - all snapshots are kept.

**Accepted / out of scope:**
- `y_ex` is a 0.x library with one main maintainer and a Rust NIF; risk
  accepted.
- A follower who unfollows while the pad is open is not kicked out of the
  open session (not a real-world issue).
- Prod is a single server, so one process per pad needs no cross-node
  coordination.

**Roadmap (estimate 2–3 weeks of focused work):**
0. Trial (½ day): two browsers editing one pad through a channel with
   `y_ex`, in dev and in a prod-like release build.
1. Data model and pad management (1–2 days): pads and snapshots tables;
   moderators create pads and toggle read only; follower-only access.
2. Collaboration core (3–5 days): first Phoenix Channel in the app, one
   process per open pad holding the Yjs document, cursors/presence, saving
   the Yjs state and markdown copy, stopping when idle, read-only reaching
   open editors.
3. Browser side (2–3 days): CodeMirror 6 + Yjs + channel connector via the
   existing esbuild/`package.json`; split view, mobile tabs, scroll sync.
4. Server-rendered preview (½ day).
5. Snapshots (1–2 days): idle timer, snapshot on last leave, "Save version"
   button, version list, restore.
6. Tests and deploy (2–3 days): channel tests with several clients,
   permission tests, NIF loading in the prod build.

A first usable version could be steps 0–4 without scroll sync (about 1½–2
weeks), with snapshots following.

---

### Miscellaneous open items

- **Logger backend for the error mails (found 2026-10-18).** The error mails
  come from the custom backend `Logger.Backends.ExceptionNotification`,
  registered via `config :logger, backends: [...]` in `config/prod.exs`.
  That key has been deprecated since Elixir 1.15 (warning at startup) but
  still works in 1.20. Options: add `{:logger_backends, "~> 1.0"}` and call
  `LoggerBackends.add/1` in the application start, or rewrite it as an
  Erlang `:logger` handler. Also (found 2026-10-19): it has no
  `handle_event(:flush, state)` clause, so it crashes with a
  FunctionClauseError whenever Logger flushes, e.g. at the end of
  `bin/pan eval` and on every stop. Harmless for the mails, one-line fix.
- **Faster compiles (found 2026-10-18).** Elixir 1.20's compiler option
  `elixirc_options: [module_definition: :interpreted]` can cut compile
  times on machines with many cores; the `.beam` files stay the same.
  Worth a try, optional.
- **Category clean-up, second look (found 2026-10-19).** The user cleans up
  categories on prod with `/admin/categories/merge` (namesakes colored, empty
  ones deletable, podcast counts) and restores a prod backup to dev on
  2026-10-20. Then look at the result again: remaining namesake groups, same
  titles meaning different things under different parents, strays that grew
  back. The parser matches titles ignoring case and surrounding spaces since
  2026-10-19; no table remembers merges (by decision), so occasional
  re-merging is the plan.
- **npm audit advisories in the build tools (found 2026-10-19).** `braces`
  3.0.3 (high, via `@tailwindcss/cli` → `@parcel/watcher` → `micromatch`) and
  `postcss-selector-parser` 6.0.10 (moderate, via `@tailwindcss/typography`
  0.5.20). Both are denial of service on hostile input and run only at build
  time on our own templates and CSS, never in the browser. `npm audit fix
  --force` would downgrade typography to 0.5.4, so not that. Check again
  after the next `@tailwindcss/cli` / `@tailwindcss/typography` releases
  (`cd assets && npm audit`).
