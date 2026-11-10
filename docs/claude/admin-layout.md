Admin LiveViews must use `use PanWeb, :admin_live_view` instead of `use PanWeb, :live_view`.

**Why:** `:admin_live_view` in `lib/pan_web.ex` sets `layout: {PanWeb.LayoutView, :live_admin}` and `container: {:div, class: "flex-1 w-full"}` automatically. Using `:live_view` would apply the wrong layout (`"live.html"` instead of `live_admin`).

**How to apply:** Any file under `lib/pan_web/live/admin/` or any Surface file that had `layout: {PanWeb.LayoutView, :live_admin}` in its `use Surface.LiveView` call should become `use PanWeb, :admin_live_view`. Do not carry over the layout option manually.
