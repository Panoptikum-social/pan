# Panoptikum design language

How color, icons and surfaces are used, so new pages fit in without a design
discussion. Themes are [Catppuccin](https://catppuccin.com/palette) Latte
(light) and Mocha (dark) on DaisyUI 5, see `assets/css/app.css`.

## Four roles

| Role | Means | Looks like |
|---|---|---|
| Colored icon | what something **is** | the entity's or the icon's own color, title in the text color |
| Color line | what a container **holds** | a panel framed in the color of its content, neutral heading |
| Neutral | everything **readable** | text, headings, links in the text color; base-100/200/300 surfaces |
| Filled color | **actions and states** | buttons, badges, flash messages; nothing else is filled |

When something new comes up: a thing gets an icon, a container gets a frame,
an action gets a filled button.

## Colors

Colors carry no meaning on their own; what matters is that the same thing
always looks the same.

- **Theme colors** (buttons, badges, alerts): primary blue, secondary mauve,
  accent pink, info sky, success green, warning yellow, error red, neutral.
  Every color/content pair meets WCAG AA (4.5:1). Latte's light accents take
  dark text (`#1e1e2e`), only blue, mauve and red take white.
- **Surfaces:** `base-100` (cards, inputs), `base-200` (page), `base-300`
  (sidebar, headings, borders, striped rows; Catppuccin surface0).
- **Text:** `text-base-content`, secondary text `text-base-content/70`.
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
- **Panels:** `Panel` with `purpose="episode"` etc.: neutral `base-300`
  heading, the whole panel framed (2px) in the purpose's color.
- **Buttons:** `class="btn btn-primary"` and the other DaisyUI variants;
  `<.button>` without a class is muted (`btn-soft`).

## Don'ts

- No fixed colors (`bg-white`, `text-gray-*`, `text-black`, the old Bootflat
  names like `bg-lavender`): they don't follow the theme.
- No gradients.
- No colored backgrounds for things that aren't actions or states.
- No white text on accent colors outside the AA-checked theme pairs.

## Themes

- Admin and moderation pages follow the Latte / Mocha / System toggle
  (`PanWeb.Component.ThemeToggle`, localStorage `pan_theme`); the theme sits
  on `<html>`, set for `/admin` and `/moderator`
  (`PanWeb.LayoutView.themed?/1`).
- The public site is on DaisyUI's `light` theme until its templates are
  converted (backlog.md, Catppuccin section).
