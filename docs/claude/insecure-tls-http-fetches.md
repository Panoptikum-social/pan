Three call sites disabled TLS certificate verification via `hackney: [:insecure]`:
- [lib/pan_web/frontend_views/page_frontend_view.ex:19](../../lib/pan_web/frontend_views/page_frontend_view.ex#L19) — fetched own blog.panoptikum.social content, also allowed TLS 1.0/1.1. **FIXED 2026-08-21**: removed `:insecure` and the old TLS versions list — user confirmed blog.panoptikum.social runs an up-to-date nginx with valid certs.
- [lib/pan/updater/feed.ex:15](../../lib/pan/updater/feed.ex#L15) — HEAD request to `feed.self_link_url`, an externally supplied/podcast-owner-controlled URL. **Intentional, confirmed by user 2026-08-21**: loosened deliberately because third-party podcast hosts commonly have broken/misconfigured cert chains; do not "fix" this without asking again.
- [lib/pan/parser/category.ex:60](../../lib/pan/parser/category.ex#L60) — restricted to TLS 1.2 only, still `:insecure`. Same: **intentional, confirmed by user**, leave in place.

**Update 2026-10-01 (HTTPoison 3 / hackney 4):** `hackney: [:insecure]` no longer skips certificate checks with hackney 4; tested, a self-signed cert is still rejected. Both intentional sites now use `ssl: [verify: :verify_none]` (category.ex: `ssl: [versions: [:"tlsv1.2"], verify: :verify_none]`), which HTTPoison 3 makes work. Behavior is unchanged and still intentional.

**Why:** Found during a general project health inspection (2026-08-21) via credo/hex.audit/grep sweep, not something obvious from reading a single file — the risk only shows up when you notice `feed.self_link_url` is user/podcast-submitted, making the insecure fetch an MITM vector on external, semi-trusted input. No CVE/dep issue, just app code.

**How to apply:** If asked to do a security pass or touch these files, flag/fix by removing `hackney: [:insecure]` and dropping TLS 1.0/1.1 from allowed versions, unless the user says it's intentional (e.g. known cert issues with old podcast hosts) — confirm before "fixing" since it may be a deliberate workaround.
