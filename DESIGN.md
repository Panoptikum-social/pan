# Panoptikum design language

How color, icons and surfaces are used, so new pages fit in without a design
discussion. Themes are [Catppuccin](https://catppuccin.com/palette) Latte
(light) and Mocha (dark) on DaisyUI 5, see `assets/css/app.css`.

## Four roles

| Role | Means | Looks like |
|---|---|---|
| Colored icon | what something **is** | the entity's or the icon's own color, title in the text color |
| Color line | what a container is **about** | a line under the panel heading, in the color of its purpose |
| Neutral | everything **readable** | text, headings, links in the text color; base-100/200/300 surfaces |
| Filled color | **actions** | the main button of a section; nothing else is filled |

When something new comes up: a thing gets an icon, a container gets a color line,
an action gets a button (filled only for the main action). No solid color
areas otherwise: labels are outline badges, messages soft alerts.

## Colors

Colors carry no meaning on their own; what matters is that the same thing
always looks the same.

- **Theme colors** (buttons, badges, alerts): primary blue, secondary mauve,
  accent pink, info sky, success green, warning yellow, error red, neutral.
  Every color/content pair meets WCAG AA (4.5:1). Latte's light accents take
  dark text (`#1e1e2e`), only blue, mauve and red take white.
- **Surfaces:** `base-100` (cards, inputs), `base-200` (page), `base-300`
  (sidebar, headings, borders, striped rows; Catppuccin surface0). In Latte
  the page is Latte base `#eff1f5` and cards are white (mantle as page
  looked gray); in Mocha the page is mantle, cards base.
- **Text:** `text-base-content`, secondary text `text-base-content/70`. In
  the light themes that is Latte text `#4c4f69`, never (almost) black:
  black text on light backgrounds looks bold.
- **Links:** text color, underlined (or underline on hover for entity
  links), `hover:text-primary`. No colored link text: Latte blue on the
  background is below AA.
- **Accents for icons and lines:** `text-ctp-<name>` / `border-ctp-<name>`
  for the 14 Catppuccin accents (rosewater, flamingo, pink, mauve, red,
  maroon, peach, yellow, green, teal, sky, sapphire, blue, lavender). In the
  light themes they are darkened to reach 3:1 on the page, Mocha uses the
  originals.
- **Violet stays rare:** mauve is secondary and the persona color, nothing
  else.

### Entity colors

| Entity | Token | Accent | Icon |
|---|---|---|---|
| Podcast | `podcast` | peach | `microphone` |
| Episode | `episode` | teal | `headphones` |
| Persona | `persona` | mauve | `user-star` |
| User | `user` | flamingo | `woman` |
| Recommendation | `recommendation` | green | |
| Category | `category` | maroon | the category's own icon |

Use them as `text-podcast`, `border-episode` and so on; they follow the
theme. Categories: each top level category has its own color (column
`categories.color`), subcategories use their parent's, see
`PanWeb.Category.color_map/0`.

## Icons

- [Tabler Icons](https://tabler.io/icons), vendored in `priv/icons/tabler`
  (outline by name, filled as `<name>-filled`, update steps in the README
  there). Render with `<.icon name="calendar" class="size-5" />` or
  `icon("calendar", class: "...")`.
- Every icon has a fixed color, see `@colors` in `PanWeb.Live.Icon`; add new
  icons there. A `text-*` color in the class overrides it.
- On filled backgrounds (filled buttons and badges, `text-white`,
  `text-*-content`) icons take the text color automatically (rule in
  `app.css`), so no blue icon on a blue button.
- Categories: own icon per category (`categories.icon`), proposals and the
  "Fill missing icons" button in `Pan.CategoryIcons`; folder as fallback.

## Components

- **Entity links:** `PodcastButton`, `EpisodeButton`, `PersonaButton`,
  `UserButton` and `CategoryLink`, all on `EntityLink` (colored icon +
  title). No label like "Podcast" in front: the icon says it.
- **Panels:** `Panel` with `purpose="episode"` etc.: one `base-100`
  surface (rounded, shadow), the heading only set apart by `font-semibold`
  and a 2px line underneath in the purpose's color. Tried and dropped: a
  frame around the whole panel (too much color), a darker `base-300`
  heading bar (too heavy). Panels side
  by side get different purposes (on My Podcasts: podcast, subscription,
  like, follow, recommendation, popular, category), not seven times the
  same color.
- **Buttons:** the main action of a section filled (`btn btn-primary`
  etc.), all others `btn-outline btn-<color>`, no soft buttons (they looked
  disabled); `<.button>` without a class is `btn-primary btn-outline`.
  Colored outline buttons show frame and text in the color; in Latte the
  light accents use darker shades (`--color-<color>-strong` for primary,
  accent, info, warning, success; 4.5:1 like red), the hover fill stays the
  theme color. An outline button without a color looks disabled next to
  colored ones.
- **Badges** (roles, types, labels; `Pill`): `badge badge-outline
  badge-<color>`, the color in the frame, the text in the text color (rule in
  `app.css`, the accents don't reach AA as small text).
- **Alerts and flash messages:** `alert alert-soft alert-<color>`, light tint,
  text in the text color.

- **QR codes:** normal polarity in both themes (dark modules on light),
  Mocha in Mocha base on Mocha text; always a light quiet zone outside the
  150px code (padding, not shrinking the code: smaller modules stopped
  phones from scanning).

## Don'ts

- No fixed colors (`bg-white`, `text-gray-*`, `text-black`, the old Bootflat
  names like `bg-lavender`): they don't follow the theme.
- No gradients.
- No solid color areas except main action buttons.
- No white text on accent colors outside the AA-checked theme pairs.

## Themes

- Latte and Mocha are the only themes (`app.css`). Without a choice the page
  follows the OS: Latte on light systems, Mocha on dark ones
  (`prefers-color-scheme`, pure CSS, no flash).
- The toggle (sun / monitor / moon, `PanWeb.Component.ThemeToggle`) sits in
  the sidebar below the menu on every page. Latte or Mocha set `data-theme`
  on `<html>`, "System" removes it; the choice is kept in localStorage
  (`pan_theme`) and applied before the first paint by a nonce'd script in
  `_head.html.heex` (CSP).
- Check new pages in both themes; a headless Chrome with
  `--blink-settings=preferredColorScheme=0` renders the dark one.
