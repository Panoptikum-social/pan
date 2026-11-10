The Elixir compiler only warns about unused *private* code; orphaned public modules need an xref sweep. The user likes these clean-ups (2026-11-06: "a codebase is a bit cleaner again").

**Recipe:** `mix xref graph --format plain` → files that appear as sources but never as `|--`/`` `-- `` targets = candidates (45 on 2026-11-06). Then check each by hand.

**Expected false positives (reached without a compile-time reference):**
- views: looked up by controller name (check the matching controller exists, and `put_view` uses)
- jobs + Pan.ExceptionNotification: started from config/prod.exs / qa.exs
- Pan.Application (mix.exs), Pan.Release (docker/entrypoint.sh)
- join-table schemas (LanguagePodcast, UserLanguage): admin data browser via `Naming.schemas()`
- `lib/pan.ex` (moduledoc-only context root)

**2026-11-06 sweep removed** (one dedicated commit each group, so they can be found in history): GridPresenter (70d48de0), CategoryView/EmailView/PageFrontendController (bf9bcab1), FixtureGenerator + Component.Tab (d8b34123), phx.gen.pretty_* mix tasks + priv/templates (301f0c92). Numbers #604–#607, see [numbered-lists](numbered-lists.md).

**Not covered:** unused public functions inside used modules.
