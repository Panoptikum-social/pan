Whenever we touch dependencies (deps.update, toolchain upgrades, mix.lock changes) or prepare a deploy, run `mix hex.audit` without being asked and report any advisories; `mix hex.outdated` shows available updates. Fix by `mix deps.update <pkg>` if the requirement allows it, then `mix compile --warnings-as-errors` + `mix test`, commit mix.lock with the CVE ids in the message.

**Why:** on 2026-10-18 the user remembered a bandit advisory by chance; `mix hex.audit` found two (CVE-2026-105659 HIGH, CVE-2026-105660 MEDIUM, fixed in bandit 1.13.0) in seconds, and html_sanitize_ex 1.5.6 was a security release too (00d572c2). User: "That's a good idea."

**How to apply:** one hex.pm request each, sequential is fine (see [no-parallel-outbound-probes](no-parallel-outbound-probes.md) for outbound rules). Check the changelog before updating packages we extend (e.g. html_sanitize_ex scrubbers, [html-sanitize-ex-scrubber](html-sanitize-ex-scrubber.md)).

**Extended 2026-11-01:** also run `cd assets && npm audit` in the same pass. `mix deps.audit` (mix_audit) is
not installed; `mix hex.audit` already reports security advisories (EEF CVEs), not only retirements. For
details and the exact fixed version, query OSV one advisory at a time: `curl -s https://api.osv.dev/v1/vulns/<id>`.
Check new releases' publish dates (fixes are often days old) and the changelog for behaviour changes (e.g.
phoenix_html 4.4.0 rejects attribute names containing quotes, `>`, `/`, `=`, spaces, control chars; Alpine
`@`/`:` names are fine). Verify an npm build-tool bump by diffing the built CSS/JS before and after. The
"Hex authentication session expired" warning is harmless for public packages. Prod deploy after such a
change needs `mix deps.get` and, if package.json changed, `npm install` (see [prod-deploy-esbuild](prod-deploy-esbuild.md)).
