Since 2026-10-31 the Panoptikum blog, user/podcaster manuals, API docs and legal pages live in
`/daten/DATA/rust/sites/blog.panoptikum.social/`, built with the user's own Rust static site
generator **qed** (`/daten/DATA/rust/qed`). Deployed at blog.panoptikum.social. Own git repo,
user deploys manually. It replaces the old Jekyll repo `/daten/DATA/jekyll/blog.panoptikum.social/`, which is
**archived**: never edit it, but use it as the reference when something on the new site looks
broken or missing (wrong rendering, lost link, missing page/image). At the migration
(2026-10-31) the content of both was identical, so any difference from before that date is a
migration bug; later edits exist only in the qed site.

qed ships an MCP server, registered in the Phoenix repo's `.mcp.json` as `qed-panoptikum-social`
(`qed mcp <site dir>`); prefer its tools for editing the site. New MCP servers need a new session.
Works in sessions since 2026-10-31 (qed 0.15.0; site_info: 75 pages, 62 posts). Tools: guide
(call once before any change), site_info, list_pages, read_page, write_page (pass the stamp from
read_page; refuses if the owner edited meanwhile → re-read), create_page, move_page,
delete_page, read_settings/write_settings (site.toml), list_files, import_file, delete_file,
find_icons, build_site (checks broken links), changes_since_publish, save_version (call after a
set of related changes, short note in the owner's words), list_versions. Every change lands in the site's history (owner can undo); publishing is
the owner's decision, done in the q.e.d. desktop app — never publish. If the tools are missing
in a session: check `/mcp`, and that the server was approved.

Layout: `site.toml` (title, themes catppuccin-latte/mocha, main_menu), `pages/*.md`
(index, api, privacy, imprint, community, complaints, code-of-conduct, no-more-pro, talks, blog),
`pages/manuals/{listener,podcaster}-manual.md`, `pages/blog/YYYY-MM-DD-slug.md`, `footer.md`,
`static/`, `media/`, `assets/`, built output `_site/`. Front matter is TOML (`+++`), see
[blog-posts](blog-posts.md). Old Jekyll URLs kept via `redirect_from`.

Old 2016–2018 blog posts are archival — don't edit them for content/style. `code-of-conduct.md`
is the verbatim Berlin CoC template — leave alone.

**Why:** the site is outside the Phoenix tree and easy to forget; docs go stale silently when
app features change (pricing, API routes like `api.md`, persona/claim flows, mutating routes
becoming POST). Check it whenever app-facing behaviour changes. Commit only files you touched,
and only when asked.

**German (2026-11-05):** `[languages.de]` in site.toml; 13 pages translated into `*.de.md` at /de/… (start page, legal/meta pages, manuals overview + 4 manuals, footer.de.md); blog and API stay English. Panoptikum links to them via `PanWeb.Blog.url/1`, whose list of translated paths must be updated when pages get translations. The hand-made main menu has German titles via `titles = { de = "…" }` per entry (#601 done 2026-11-06); new menu entries need one too. German style: [german-style](german-style.md).


**2026-11-06:** site title "Panoptikum Docs" (de "Panoptikum Doku"), last menu entry "Back to Panoptikum"; "Panoptikum.social" replaced by "Panoptikum" in all page texts incl. the old blog posts (user OK'd that exception to "archival", see [panoptikum-name](panoptikum-name.md)). Start page + imprint: contact is the fediverse address @panoptikum@fosstodon.org (also `profiles` in site.toml), not Twitter; site described as made with q.e.d.; GitHub org is **Panoptikum-social** (old PanoptikumIO/panoptikumio links redirect or 404). The site now has a public GitHub repo https://github.com/Panoptikum-social/blog.panoptikum.social (no remote set in the local git yet; `targets.toml` and `_site/` are gitignored; a README waits for a qed feature). History = the site's git repo: save_version commits everything changed, also files edited directly (sed) — handy for many one-line edits instead of whole-page write_page.

**Lock (2026-11-06):** while a Claude session has the `qed mcp` server running (started from `.mcp.json`), the site is locked and the user can't open it in the q.e.d. desktop app. No lock file, the process holds it. Ending it myself (`kill`) was blocked by the permission check; the user ends it via `/mcp` (disable qed-panoptikum-social), `kill <pid>` or by ending the session. Before that: make sure everything is saved as a version (`git status` in the site dir clean). When the user wants to publish or work in the app, mention this upfront.
