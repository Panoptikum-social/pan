**Panoptikum** — a podcast discovery/tracking platform (panoptikum.social). OTP app name `pan`, at `/daten/DATA/phoenix/pan`. Elixir/Phoenix/Postgres, LiveView-heavy, actively maintained by the user.

## lib/ structure
- `lib/pan/` — domain logic: parser, updater, search, activity_pub, job, mailer
- `lib/pan_web/` — web layer: controllers, live views, components, layouts

## PanWeb macros (lib/pan_web.ex)
- `use PanWeb, :live_view` — sets layout `{PanWeb.LayoutView, "live.html"}`
- `use PanWeb, :admin_live_view` — sets layout `{PanWeb.LayoutView, :live_admin}`, container `{:div, class: "flex-1 w-full"}`
- `use PanWeb, :live_component` — plain LiveComponent
- `use PanWeb, :html` — Phoenix.Component (function components)

## Router structure (lib/pan_web/router.ex)
- `live_session :admin, on_mount: {PanWeb.Live.Auth, :admin}` — admin routes under `/admin`
- Pipeline `:admin_layout` — `plug(:put_layout, html: {PanWeb.LayoutView, :admin})`
- Frontend routes for podcasts, episodes, personas, categories, recommendations, search

**Why:** Need to understand this to navigate between domain logic and web layer.
**How to apply:** When editing admin LiveViews, check whether they need `:admin_live_view`. When looking for business logic, check `lib/pan/` not `lib/pan_web/`. Don't memorize exact dependency versions here — they drift; check `mix.exs` directly when it matters (e.g. advising on API changes). Surface (`lib/pan_web/surface/`, the `:surface` dep) is fully gone — migrated to native Phoenix components, see [live-component-call-syntax](live-component-call-syntax.md) and related `feedback_surface_*` entries for the conversion patterns, still relevant if any stray Surface-era code shows up.
