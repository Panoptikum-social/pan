`<.button>` without an explicit `class=` attribute falls back to `btn btn-soft` in DaisyUI v5, which renders as a muted/low-contrast style that looks like a link, not a button.

Always pass an explicit class:
```heex
<.button type="submit" class="btn btn-primary">Label</.button>
```

**Why:** `PanWeb.CoreComponents.button/1` has a variant map where `nil → "btn-primary btn-soft"`. In DaisyUI v5, `btn-soft` is a muted soft variant — fine for secondary actions, but visually link-like on light backgrounds. Discovered when `episode/recommend_form.ex` used `<.button type="submit">` without class while `podcast/recommend_form.ex` correctly had `class="btn btn-primary"`.

**How to apply:** When writing or reviewing a `<.button>`, always check that `class=` is set. The chapter recommend form uses `class="btn btn-primary"` on `<.button>` as the correct reference.
