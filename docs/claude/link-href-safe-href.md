Always pass feed- or user-supplied URLs (podcast website, payment link, persona uri, community website, ...) to `<.link>` as `href={safe_href(value)}`, guarded by `:if={safe_uri?(value)}`. Both helpers are in `PanWeb.CoreComponents`.

**Why:** `Phoenix.LiveView.Utils.valid_string_destination!/2` does a case-sensitive prefix match on the raw string. It raises `ArgumentError` ("unsupported scheme given to <.link>") on `HTTPS://…`, ` https://…` or any unlisted scheme, and that crashes the whole page. `URI.parse/1` lowercases the scheme and treats a leading space as "no scheme", so a check based on it doesn't match LiveView's. The persona page crashed this way on 2026-09-25. The user chose to normalise (trim + lowercase the scheme) rather than render those URLs as plain text.

**How to apply:** Never check URLs with `URI.parse` for `<.link>`. When adding a new link site for external data, use `safe_href/1`. Check the result against LiveView's own function, not just `URI.parse`.
