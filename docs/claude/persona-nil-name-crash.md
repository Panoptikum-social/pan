Show page tolerates `name: nil` since 2026-09-17 (`persona.name || "Persona"` in
`lib/pan_web/live/persona/show.ex`).

**Cause (found 2026-10-12, #57):** commit 836de3d1 (2026-09-05) added
`Map.update(key, nil, &only_if_string/1)` for :uri/:email/:name in
`Pan.Parser.Persona.get_or_insert/1`. That inserts `nil` for missing keys, so the
`put_new` defaults (name from email local part, uri = email) never applied.
Result: 137 email-only `itunes:owner` personas with NULL name (the 58 from
2026-09-17 were part of these), and ~3,044 email-only personas without uri.
Unexplained: none created after 2026-10-01 12:06, although the bug was still there.

**Fix #115 (2026-10-12, commit be8ee05b, deployed 2026-10-12):** non-string values are dropped with `Map.reject`, so
the keys stay missing; regression tests in `test/pan/parser/persona_test.exs`.

**Backfill #116:** names derived exactly like the parser + `full_text: false`
on persona and its podcasts/episodes (Manticore). Done on dev 2026-10-12;
now a button "Fix nameless personas" on /admin/databrowser/persona (`MaintenanceController.fix_nameless_personas`, uses `Pan.Parser.Persona.name_from_email/1`). Prod: run successfully 2026-10-12 (user confirmed).

Closed by decision (2026-10-12, user: "we won't handle them"): #117 uri = email backfill for ~3,044 personas (cosmetic).
Side note: Acast owner emails `info+<uuid>@mg-eu.acast.com` yield names like
"Info+bf0792d1-…" (80 personas) — the long-standing rule, not changed (#118, closed). Don't bring either up again.
