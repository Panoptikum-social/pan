`attr` and `slot` declarations must be placed **immediately before** the component function (`render/1` or any named component function). Any `def` or `defp` between the declarations and the component function causes Phoenix.Component to attach the attrs to that intermediate function instead.

**Why:** This caused two bugs in the Surface → Phoenix migration: Panel and TopList both had helper functions (`heading_color_classes/1`, `prepare_for_toplist/1`) between the attr declarations and `render/1`, leading to KeyError and BadMapError at runtime.

**How to apply:** When reviewing or writing Phoenix components, always move helper functions (`defp`) above the `attr`/`slot` block. The correct order is:

1. Helper functions (`defp`)
2. `attr` / `slot` declarations
3. `def render(assigns)` (or named component function)
