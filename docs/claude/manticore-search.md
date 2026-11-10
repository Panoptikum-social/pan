Manticore Search runs on `http://localhost:9308`. Four RT tables: `categories`, `episodes`, `personas`, `podcasts`. Managed via `Pan.Search.Manticore` in `lib/pan/search/manticore.ex`.

## Endpoint → content type mapping

| Endpoint | Content-Type | Notes |
|---|---|---|
| `sql?mode=raw` | `application/x-www-form-urlencoded` | body must be `query=<URI-encoded SQL>` |
| `replace` | `application/json` | upsert a single document |
| `delete` | `application/json` | delete a single document by id |
| `bulk` | `application/x-ndjson` | batch insert (newline-delimited JSON) |

## sql/1 helper

`Manticore.sql("DROP TABLE episodes")` — wraps the SQL endpoint correctly: puts `mode=raw` in the URL and uses `URI.encode_www_form/1` on the query value so `=` signs inside SQL (e.g. `min_infix_len='2'`) don't corrupt the form body.

**Why:** `mode=raw` in the POST body caused "query missing" errors; `=` signs in SQL option values (`html_strip='1'`, `html_remove_elements = '...'`) would corrupt the `query` form field if unencoded.

Since 2026-10-01 the `bulk` lines use `replace` (and `delete` for excluded records), not `insert`. Raw SQL also works for paging and deleting: `SELECT id FROM t WHERE id > N ORDER BY id ASC LIMIT 10000 OPTION max_matches=10000`, and `DELETE FROM t WHERE id IN (...)`. JSON attributes (e.g. `categories`, `gigs`) come back as JSON *strings* from the SQL endpoint, so `Jason.decode!` them. See [manticore-podcast-sync](manticore-podcast-sync.md).

**How to apply:** Always use `Manticore.sql/1` for DDL and any raw SQL. Use `Manticore.post/3` only for `replace`, `delete`, and `bulk` endpoints with explicit content types.
