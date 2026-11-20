To update one Hex package without moving its dependencies: `mix deps.unlock <pkg>` then `mix deps.get`. Check `git diff mix.lock` afterwards: only that package's line may change.

**Why:** on 2026-11-20 `mix deps.update swoosh` also unlocked swoosh's dependencies and pulled in hackney 4.10.2 → 4.12.2, idna 8.0.0, certifi, h2, quic and webtransport. That was exactly the hackney jump the user had just deferred (#715). `deps.unlock swoosh` + `deps.get` resolved swoosh 1.30.0 against the existing lock, so nothing else moved.

**How to apply:** use `mix deps.update` only when its transitive updates are wanted too. After reverting a too-wide update with `git checkout mix.lock`, `mix deps.get` puts `deps/` back on the locked versions (it prints "Updating ..." for each one); verify with the version in `deps/<pkg>/hex_metadata.config`. Then compile, test, `mix hex.audit`, `cd assets && npm audit` ([hex-audit](hex-audit.md)), and ask the user to restart the dev server.

Advisories can be withdrawn: on 2026-11-20 `npm audit` dropped GHSA-fc5q-39xc-vjpf (picomatch, withdrawn 2026-11-18) with nothing changed locally. When an audit result changes unexpectedly, check the advisory on osv.dev (`https://api.osv.dev/v1/vulns/<id>`: `withdrawn`, `affected` ranges) before concluding anything.
