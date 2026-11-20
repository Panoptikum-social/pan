# Backlog

Open work items and pending design decisions, kept here (rather than only in
Claude's per-machine memory) so they survive across computers. Last synced
2026-11-05.

---

## Open backlog items

### Miscellaneous open items

- **Revisit the category merge (next days, from 2026-10-21).** The mapping
  table (1c6a0807, Mappings tab on /admin/categories/merge, 34 old Apple
  names seeded) went to prod 2026-10-21, with the stray merges there. Check
  whether old names still come back while the monthly metadata refresh runs
  through the podcasts (rotation until about 2026-11-21), and merge any new
  strays (sub before parent, so the mapping gets the name feeds use).
  Last check 2026-11-18 (next: any id above 2857).

- **#707 Persona warning page links the fediverse address.**
  `persona_frontend/warning.html.heex` renders `<a href={@persona.fediverse_address}>`,
  but the values are handles (`@name@host`), so the link is a broken
  relative URL (found 2026-11-20 during #705).
- **#708 `mix credo --strict` findings.** 2 refactoring opportunities, 153
  code readability issues, 51 software design suggestions (2026-11-20);
  plain `mix credo` is clean on the files touched by #705. To be tackled
  separately.

### Later dependency updates (waiting for an upstream fix)

- **#640 npm audit: picomatch ReDoS** (GHSA-fc5q-39xc-vjpf, 4 high entries
  for one issue) via micromatch → `@parcel/watcher` → `@tailwindcss/cli`
  4.3.x, the Tailwind CLI's file watcher: build time only, never in the app
  or the browser (prod only runs the CLI while building the release).
  Tried and reverted 2026-11-18:
  - No fixed picomatch exists: the advisory covers `<= 4.0.7`, the newest
    release. `npm audit fix` still says "fix available", but afterwards
    audit reports the same advisory on picomatch 4.0.7 (3 entries).
  - The fix would have moved Tailwind 4.3.3 → 4.3.5 (lightningcss 1.33,
    @parcel/watcher 2.6, micromatch dropped). JS builds were
    byte-identical, but 4.3.5 drops DaisyUI's `.join` focus/hover
    `z-index` rules ("Invalid empty selector" warnings in the build),
    which affects theme_toggle.ex and language_toggle.ex.
  - @parcel/watcher's install script (npm 11 `allowScripts` warning) is a
    no-op unless `npm_config_build_from_source=true`; no approval needed.
  Wait for a fixed picomatch release, then retry; diff the built CSS/JS
  before and after (minified builds, check for dropped rules and new
  build warnings). Prod deploy then needs `npm install`.
