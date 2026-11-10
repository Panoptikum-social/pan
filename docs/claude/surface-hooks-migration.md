Surface auto-collected `*.hooks.js` sidecar files placed next to components (e.g. `lib/pan_web/live/episode/podlove_player.hooks.js`) into `assets/js/_hooks/index.js`. When Surface was removed, `_hooks/index.js` was replaced with an empty export, silently dropping all hooks.

Three hooks were lost this way:
- `PodlovePlayer` — in `lib/pan_web/live/episode/podlove_player.hooks.js` → copied to `assets/js/podlove_player.js`
- `PodloveSubscribeButton` — in `lib/pan_web/live/podcast/podlove_subscribe_button.hooks.js` → was replaced by a non-functional TODO stub in `app.js`
- `MarkdownField` — in `lib/pan_web/surface/markdown_field.hooks.js` → copied to `assets/js/markdown_field.js`

All three are now imported and registered in `assets/js/app.js` under `hooks: { ..., PodlovePlayer, PodloveSubscribeButton, MarkdownField }`.

**Why:** Surface's hook auto-collection mechanism was invisible — no explicit import in `app.js`, so it was easy to miss when removing Surface.

**How to apply:** When removing Surface or auditing hooks, search for all `*.hooks.js` files under `lib/` and ensure each is manually imported in `assets/js/app.js` and registered in the `hooks:` object. Check `phx-hook="X"` usages in templates to confirm every hook name has a corresponding registration.
