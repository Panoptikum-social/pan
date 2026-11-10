On 2026-10-12, after bumping `check_my_feed` 0.1.0 → 0.2.0 (and briefly testing
against a temporary `path: "../check-my-feed"` dep, then restoring mix.exs/mix.lock),
VS Code showed an ElixirLS error on `mix.exs`: `(Mix.Error) Can't continue due to
errors on dependencies` (from `deps.loadpaths`), while `mix compile`, `mix test`
and the dev server were all fine.

ElixirLS builds separately in `.elixir_ls/build/test` (MIX_ENV=test), not `_build`,
so its dependency state can go stale after dep changes. Exact cause wasn't
confirmed (its check_my_feed build dated from 2026-09-20).

The user's fix: delete `.elixir_ls/` and restart VS Code. They stopped me from
investigating further.

**Why:** it's an editor-cache problem, not a project problem; the CLI is the truth
(see [stale-ide-diagnostics](stale-ide-diagnostics.md)).
**How to apply:** if this error shows up again after a dependency change, suggest
deleting `.elixir_ls/` and restarting the editor rather than digging into it.
When testing Pan against an unpublished library, mention this side effect up front.
Related: [feed-compliance-checker](feed-compliance-checker.md).
