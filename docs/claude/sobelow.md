Since 2026-10-19 `{:sobelow, "~> 0.16", only: [:dev, :test], runtime: false}` is a dep (8a193e44).

- `.sobelow-conf`: `ignore: ["Config.HTTPS"]` (TLS ends at nginx), `skip: true`.
- `# sobelow_skip ["Config.CSRF"]` above `pipeline :json_api` in the router: PanWeb.Api.Auth only accepts a token from the Authorization header.
- `.sobelow-skips` (085e73b4): fingerprints of all 73 findings reviewed that day — Config.CSP (CSP comes from PanWeb.ContentSecurityPolicy, which Sobelow doesn't recognize, see [content-security-policy](content-security-policy.md)), Config.CSWH (check_origin set in prod), pattern-only traversal on uploads cleaned by PanWeb.Upload.safe_filename/1, String.to_atom in admin code, raw/1 on sanitized markdown/icons, SQL built from Ecto's to_sql, the QR code SVG.
- A plain `mix sobelow` therefore reports 0; a new finding shows up (verified with a probe controller), and a skipped spot reappears when its code changes. Re-review it then, don't blindly re-run `--mark-skip-all`.

Real findings fixed that day: upload path traversal (3f1b8a58), CSP added and enforced. The follow-up OPML/XML check found the xmerl atom-exhaustion DoS (Pan.Parser.XmlNames, cc625d52). Mapping of the numbered items: [numbered-lists](numbered-lists.md) #238–#259.

**Why:** user asked for Sobelow "to hunt for known vulnerabilities"; for CVEs in deps the tool would be mix_audit (not added), `mix hex.audit` only covers retired packages ([hex-audit](hex-audit.md)).
**How to apply:** run `mix sobelow` after security-relevant changes and before deploys that touch controllers, uploads or the router; any output is new and needs a look.
