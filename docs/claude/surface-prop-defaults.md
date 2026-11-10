In Surface, `prop(name, type, required: false, default: val)` and `data(name, type, default: val)` silently provide defaults when the caller omits the value. In Phoenix LiveComponents, missing keys crash with `KeyError` at runtime.

**Pattern:** When converting a Surface LiveComponent, every `prop` or `data` with a default that is NOT guaranteed to be passed by every caller must be added to `mount/1`.

Example — `ModerationGrid` was missing from `mount/1`:
- `records: []` (was `prop(records, :list, default: [])`)
- `per_page: 20` (was `prop(per_page, :integer, default: 20)`)
- `path_helper: nil` (was `prop(path_helper, :atom, required: false)`)
- `class: nil` (was `prop(class, :css_class, required: false)`)
- `color_class: "from-bittersweet-light via-bittersweet to-bittersweet-light"` (was `prop(color_class, ...)`)

**Why:** Surface resolved defaults at compile time from prop declarations; Phoenix has no such mechanism — `mount/1` is the only place to establish defaults for internal or optional-external state.

**How to apply:** When a LiveComponent crashes with `KeyError: key :X not found`, check the original Surface file (`git show <commit> -- <file>`) for `prop(X, ..., default: ...)` declarations and add them to `mount/1`. Audit all `prop` declarations with defaults or `required: false` before finishing conversion of any LiveComponent.
