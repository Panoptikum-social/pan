In Surface, `<ComponentName prop={val} />` automatically handled both function components and live components. The migration convention `<ModuleName.render prop={val} />` only works for **function components** (`use PanWeb, :html`).

For **live components** (`use PanWeb, :live_component`), calling `.render` directly bypasses `mount/1`, `update/2`, and `handle_event/3` — the component renders with only the explicitly passed assigns, crashing on any assign set by `update/2`.

**Correct call syntax:**
```heex
<%!-- Function component (use PanWeb, :html) --%>
<ModuleName.render prop={val} />

<%!-- Live component (use PanWeb, :live_component) --%>
<.live_component module={ModuleName} id="unique-id" prop={val} />
```

**Example bug:** `LikeButton` is a live_component that sets `liking` in `update/2`. `chapter_list.ex` called it as `<LikeButton.render ...>`, so `@liking` was never set → `KeyError` at render time.

**How to apply:** Before converting a `<ComponentName>` call, check the component's first line:
- `use PanWeb, :html` → use `ModuleName.render`
- `use PanWeb, :live_component` → use `<.live_component module={ModuleName} id="..." />`
