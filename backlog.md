# Backlog

Open work items and pending design decisions, kept here (rather than only in
Claude's per-machine memory) so they survive across computers. Last synced
2026-11-05.

---

## Open backlog items

### Miscellaneous open items

- **Revisit the category merge (next days, from 2026-10-21).** The mapping
  table (1c6a0807, Mappings tab on /admin/categories/merge, 34 old Apple
  names seeded) went to prod 2026-10-21, with the stray merges there. Check
  whether old names still come back while the monthly metadata refresh runs
  through the podcasts (rotation until about 2026-11-21), and merge any new
  strays (sub before parent, so the mapping gets the name feeds use).
  Last check 2026-11-18 (next: any id above 2857).

- **#708 `mix credo --strict` findings.** 2 refactoring opportunities, 153
  code readability issues, 51 software design suggestions (2026-11-20);
  plain `mix credo` is clean on the files touched by #705. To be tackled
  separately.

### Later dependency updates (waiting for an upstream fix)

- **#715 idna CVE: EEF-CVE-2026-117678 (MEDIUM)** in idna 7.1.0: punycode
  labels are decoded before the 63-octet length check, so a long `xn--`
  label costs super-linear CPU. Fixed only in idna 8.0.0 (2026-11-12).
  Blocked by hackney 4.10.2 (`idna ~> 7.1.0`); hackney 4.12.x requires
  `idna ~> 8.0.0`, along with certifi 2.19, quic 3.x, webtransport 0.5.12
  and a newer h2. Deferred 2026-11-20 because hackney 4.12.2 was only one
  day old. When doing it: check that hackney 4.12 still reads
  `default_protocols` from the app env ([hackney-http2-disabled](docs/claude/hackney-http2-disabled.md)),
  run the tests, probe a few real feeds sequentially (incl. the 4 MB feed
  of podcast 3872), then `mix hex.audit` and `npm audit`.
