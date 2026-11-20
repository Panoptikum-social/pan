Since 2026-10-19 `{:sobelow, "~> 0.16", only: [:dev, :test], runtime: false}` is a dep (8a193e44).

- `.sobelow-conf`: `ignore: ["Config.HTTPS"]` (TLS ends at nginx), `skip: true`.
- `# sobelow_skip ["Config.CSRF"]` above `pipeline :json_api` in the router: PanWeb.Api.Auth only accepts a token from the Authorization header.
- `.sobelow-skips` (085e73b4): fingerprints of all 73 findings reviewed that day — Config.CSP (CSP comes from PanWeb.ContentSecurityPolicy, which Sobelow doesn't recognize, see [content-security-policy](content-security-policy.md)), Config.CSWH (check_origin set in prod), pattern-only traversal on uploads cleaned by PanWeb.Upload.safe_filename/1, String.to_atom in admin code, raw/1 on sanitized markdown/icons, SQL built from Ecto's to_sql, the QR code SVG.
- A plain `mix sobelow` therefore reported 0 until sobelow 0.19 (3a840c33, 2026-11-17): it has new checks and fingerprints and reported 30 findings; all re-reviewed and fixed or marked the same day (#647–#650), so a plain `mix sobelow` reports 0 again. A sobelow version bump can invalidate `.sobelow-skips`. Otherwise a new finding shows up (verified with a probe controller), and a skipped spot reappears when its code changes. Re-review it then, don't blindly re-run `--mark-skip-all`.

Real findings fixed that day: upload path traversal (3f1b8a58), CSP added and enforced. The follow-up OPML/XML check found the xmerl atom-exhaustion DoS (Pan.Parser.XmlNames, cc625d52). Mapping of the numbered items: [numbered-lists](numbered-lists.md) #238–#259.

**Why:** user asked for Sobelow "to hunt for known vulnerabilities"; for CVEs in deps `mix hex.audit` reports EEF security advisories too, mix_audit is not added ([hex-audit](hex-audit.md)).
**How to apply:** run `mix sobelow` after security-relevant changes and before deploys that touch controllers, uploads or the router; any output is new and needs a look.

**2026-11-17 review (sobelow 0.19):** real findings fixed: podcast summary rendered raw unsanitized → scrubbed at render in podcast/header.ex (#647; not at parse time, because other places show the summary escaped and would then show `&amp;`); search highlights → `Pan.Search.highlight_html/1` escapes everything but the match markers, because Manticore strips tags from snippets but decodes entities into live markup (#648, verified with `CALL SNIPPETS`); `Pan.ActivityPub.Net` no longer pins TLS 1.0–1.2 (#649). The other 27 marked as known (#650, reasons in [numbered-lists](numbered-lists.md)).

**2026-11-20 (#710):** `Crypto.WeakHash` in `Pan.Parser.Helpers.md5hash/1` reappeared after helpers.ex changed (039c5690). Re-marked as known: the MD5 hash only detects whether feed content changed, there is no security property involved (user's decision). If it shows up again after edits to helpers.ex, re-mark it without a new review.
