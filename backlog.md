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

### sobelow 0.19 findings (from 2026-11-17)

The update to sobelow 0.19 (3a840c33) brought 30 findings back, which
0.16's `.sobelow-skips` had covered (see docs/claude/sobelow.md).

- **#644 Findings from checks new in 0.19.** Crypto.WeakHash: MD5 for the
  API ETag (lib/pan_web/api/helpers.ex) and for feed change detection
  (`Pan.Parser.Helpers.md5hash/1`). Config.TLSVerify: lib/pan/updater/feed.ex
  and lib/pan/parser/category.ex (see docs/claude/insecure-tls-http-fetches.md).
  DOS.Regex: dynamic regex in lib/pan/parser/leniency.ex.
- **#645 `Pan.ActivityPub.Net` TLS versions.** Config.WeakTLS: its `@options`
  allow TLS 1.0, 1.1 and 1.2 only (legacy protocols in, TLS 1.3 out).
- **#646 Re-review all 30 findings** and record the verdicts in
  `.sobelow-skips`, as on 2026-10-19. About two-thirds are categories
  reviewed then (XSS.Raw on sanitized markdown, upload traversal,
  Config.CSP, SQL from `to_sql`), apparently fingerprinted anew by 0.19.
