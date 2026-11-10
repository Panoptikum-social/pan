In Phoenix 1.8, the correct configuration for controllers that use legacy view modules (`MyControllerView`) is:

```elixir
use Phoenix.Controller,
  namespace: PanWeb,
  formats: [html: "View", json: "View"],
  layouts: [html: {PanWeb.LayoutView, :app}, json: JaSerializer.PhoenixView]
```

**Why:** Three things must work together:
- `namespace: PanWeb` — enables per-controller view lookup (`UserFrontendController` → `UserFrontendView`)
- `formats: [html: "View", json: "View"]` — the string suffix form tells Phoenix to append `"View"` to the controller module name to find the template module; suppresses the "must receive :formats option" compiler warning
- `layouts:` — specifies the layout wrapper, separate from the template module

**What breaks without this:**
- `formats: [html: PanWeb.LayoutView]` (module form) → all controllers look for templates in `PanWeb.LayoutView` instead of their own view modules → `KeyError` / "no template defined" at runtime
- `namespace: PanWeb` without `formats:` → correct runtime behavior but a compiler warning per controller

**How to apply:** Set this once in the `def controller` block of `pan_web.ex`. Affects every controller in the app.
