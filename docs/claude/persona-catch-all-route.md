`live("/:pid", Live.Persona.Show, ...)` in the browser scope of router.ex matches any one-segment path before later scopes, so `/curator` rendered an (empty) persona page with 200 for everyone, and the `authenticate_curator` plug never ran.

**Why:** found 2026-10-01 only because an anonymous curl to `/curator` returned 200 instead of a redirect.
**How to apply:** give new areas a sub-path start page (`/curator/my_curations`, like `/moderator/my_moderations`), or place the scope before the catch-all. After adding routes, curl them logged-out and check the log's "Processing with" line names the intended LiveView.
