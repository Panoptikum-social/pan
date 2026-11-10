`%{}` matches ALL maps in Elixir pattern matching, not just empty ones. Adding a `%{}` fallback clause BEFORE a more specific clause like `%{"key" => value}` means the fallback always fires and the specific clause never runs.

**Why:** Added a `handle_event("set-language-filter", %{}, socket)` no-op clause before the real handler — it swallowed all events including valid ones with params, silently breaking the language filter.

**How to apply:** Fallback/catch-all map clauses must go AFTER all specific clauses, and even then `%{}` is a superset of everything so a no-op fallback is usually the wrong tool. Fix the source of bad params instead.
