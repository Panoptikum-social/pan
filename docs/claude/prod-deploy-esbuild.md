The release is built on prod. When `config :esbuild, version:` changes (e.g. 0.13.10 → 0.28.2 in pads step 0), prod complains about an outdated esbuild; `mix esbuild.install` fails until `mix deps.get` has fetched the new esbuild hex package. Order that worked on 2026-10-20 (pads deploy): `mix deps.get` → `mix esbuild.install` → redeploy, all inside the app checkout (as the deploy user). In the home dir asdf falls back to `~/.tool-versions`, which still named elixir 1.15.7-otp-26 (not installed) on 2026-10-20.

**Why:** found during the first pads deploy (steps 0–4, up to 4623eeaf).

**How to apply:** when preparing a deploy whose diff touches the esbuild version (or tailwind's), tell the user up front to run these steps. Also mention `npm install` in assets/ when package.json changed, and that y_ex's precompiled NIF needs glibc ≥ 2.34 (see [community-pads](community-pads.md)).
