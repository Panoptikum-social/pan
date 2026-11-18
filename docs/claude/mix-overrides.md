The user asked on 2026-10-01 whether the `override: true` entries in mix.exs could go.

- **gettext override: removed 2026-11-18** with the Timex 4.0 update (#642). Timex 4.0 accepts `gettext ~> 0.26 or ~> 1.0`; the only other package requiring gettext is check_my_feed (`~> 1.0`).
- **`{:inflex, github: "warmwaffles/inflex", branch: "master", override: true}`:** needed only by `ja_serializer` 0.18.2, its latest version (`~> 2.0`); the app doesn't use Inflex. The fix, upstream PR nurugger07/inflex#99 "Make regexes OTP28 compatible", is still open, and the last Hex release, 2.1.0, is from 2020. `mix.lock` pins the fork to commit cc8b7d3.
  - *When it can go:* PR #99 merged and released on Hex, or `ja_serializer` dropped.

**Why:** saves re-checking from scratch next time.
**How to apply:** when asked about these overrides again, check only whether that condition has changed: the state of PR #99, a new inflex release on Hex.

**npm override in `assets/package.json` (added 2026-11-01, 47f1ac55, deployed):**
- **`"postcss-selector-parser": "^6.1.5"`:** `@tailwindcss/typography` 0.5.20 (latest) pins exactly 6.0.10,
  which has GHSA-rj75-hqrm-r3gf (moderate, quadratic parsing, build time only). Built CSS was byte-identical
  with 6.1.5. `npm audit fix --force` would downgrade typography to 0.5.4 — never do that.
  - *When it can go:* a typography release that requires postcss-selector-parser >= 6.1.5.
- `"lib0": "$lib0"` was there before (yjs/y-phoenix-channel share one lib0).
- braces 3.0.3 (via @tailwindcss/cli → @parcel/watcher → micromatch) was flagged on 2026-10-19 but is no
  longer reported by `npm audit` (unchanged package, advisory DB changed); the old backlog item was closed.
