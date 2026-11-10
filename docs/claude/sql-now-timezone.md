On 2026-10-02 the Podbean data migration (6a000c9c) set `next_update = now()` via plain SQL. On dev (session TimeZone Etc/UTC) that was fine; on prod the 875 podcasts did NOT show as stale — prod's Postgres session time zone is evidently local (Vienna), so `now()` cast into the `timestamp without time zone` column was ~2 h ahead of the app's UTC. Fixed on prod via remote console with `NaiveDateTime.utc_now()` as a parameter (876 stale afterwards).

**Why:** the app stores naive UTC everywhere (`Pan.Parser.MyDateTime.now/0`); dev can't reproduce the shift.

**How to apply:**
- In SQL migrations/console snippets writing naive timestamps, use `now() AT TIME ZONE 'UTC'` or pass `NaiveDateTime.utc_now()` as a parameter — never bare `now()`.
- With a parameter used in arithmetic (`$1 - interval '1 day'`), cast it: `$1::timestamp`, else Postgres infers interval and errors (42883).
- Test remote-console snippets against dev via tidewave before handing them over.
