Manual Tailwind utility combinations were replaced with DaisyUI v5 component
classes in 2026-04 (Phoenix 1.8 upgrade, `@plugin "daisyui"` in
`assets/css/app.css`). New UI should use these classes from the start.

## Theme content colors (#58 closed 2026-10-12, 6d04e996, deployed)
DaisyUI v5 computes `-content` (text) colors from the background via OKLCH; for
some custom colors that gives poor contrast. Overrides in the
`@plugin "daisyui/theme"` block in `app.css`: `--color-error-content`,
`--color-info-content` and `--color-primary-content` are all `white` (user
checked buttons, badges and flashes in the browser). `btn-success` /
`btn-warning`: DaisyUI's dark text is fine, leave as is. Only DaisyUI component
classes use these (`btn-*`, `badge-*`, `alert-*`); `bg-info` + explicit text
classes are unaffected.

**How to apply:** when adding a semantic color to the theme, check the computed
content color in the browser and add an explicit `-content` override if it looks off.

## Conventions
- **`.btn` font override** in `app.css`: `font-weight: normal; font-size: 1rem;`
  (DaisyUI defaults to semibold and smaller).
- **Buttons:** `btn btn-primary|info|warning|error|success` (+ `btn-sm`);
  `LinkButton` base is `btn btn-sm`; custom colors (lavender, aqua, bittersweet,
  mint) stay as overrides on `btn`. `<.button>` needs an explicit class, see
  [core-components-button](core-components-button.md).
- **Never `btn-ghost` as a replacement** for a button with a visible background or
  border: in v5 it's transparent and borderless, invisible on light backgrounds.
  Use `btn-outline` for bordered navigation-style buttons; explicit
  `bg-white hover:bg-gray-lighter text-black border-gray` only where a white fill
  is needed (PodcastButton, CategoryButton cycle entry 0).
- **Tables:** `table table-zebra table-xs my-4 w-auto`, no manual cell borders or
  `odd:bg-*`. No `flex` on `<td>`, see [no-flex-on-td](no-flex-on-td.md).
- **Inputs:** `input input-bordered` (`input-bordered` is needed for a visible
  border; add `w-full` to fill the container), `textarea`, `file-input`. The old
  `text_input`-style helpers are gone since phoenix_html_helpers was removed
  (512c4724, 2026-05-15); use `<.input>` or plain `<input class=...>`.
- **Badges:** `badge badge-info|error|warning`; custom colors as override on `badge`.
- **Alerts:** form changeset error boxes `alert-danger`; layout flashes
  `alert-info empty:hidden` / `alert-danger empty:hidden`.
