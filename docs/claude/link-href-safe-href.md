Render external links in templates (podcast website, payment link, persona uri, community website, enclosures, feed URLs, ...) with `<.external_link href={value}>…</.external_link>` from `PanWeb.CoreComponents` (#705, 2026-11-20). The component:

- runs `href` through `safe_href/1` and renders the content as plain text when the value isn't safe, so no `:if={safe_uri?(value)}` guard or `<span>` fallback is needed at the call site;
- sets `target="_blank"` only for http(s) links (not `mailto:`/`tel:`, which would open an empty tab);
- always sets `rel="noopener noreferrer"`; extra values via `rel`, e.g. `rel="me"` on persona and community pages (Mastodon verification);
- adds `underline hover:text-primary` to the link; `class` (layout classes such as `truncate`, `col-span-2`) goes on the link and on the plain-text fallback.

Links styled as buttons (the "tweet" buttons in the recommendation lists) set `target="_blank" rel="noopener noreferrer"` by hand, since the component forces the text-link styling. Links to the blog domain via `PanWeb.Blog.url/1` also carry the attributes by hand; they are constant URLs and need no `safe_href`.

**Why:** the user wants external links to open in a new tab, set on the server, not by a JavaScript click handler (#703). And `Phoenix.LiveView.Utils.valid_string_destination!/2` does a case-sensitive prefix match on the raw string. It raises `ArgumentError` ("unsupported scheme given to <.link>") on `HTTPS://…`, ` https://…` or any unlisted scheme, and that crashes the whole page. `URI.parse/1` lowercases the scheme and treats a leading space as "no scheme", so a check based on it doesn't match LiveView's. The persona page crashed this way on 2026-09-25. The user chose to normalise (trim + lowercase the scheme) rather than render those URLs as plain text.

**How to apply:** For a new external link in a template, use `<.external_link>`, not a bare `<a>` or `<.link>`. Never check URLs with `URI.parse` for links. If you need `safe_href/1` directly, check the result against LiveView's own function, not just `URI.parse`. Links inside rendered Markdown are a separate case (#706).
