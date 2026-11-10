Adding `defp f(%User{email_verified: true} = user)` to lib/pan_web/controllers/auth.ex made `mix compile --force` fail with "module PanWeb.Router.Helpers is not loaded" (8 errors, root cause not shown). Incremental `mix compile` and dev runs hid it; only a forced/full compile (e.g. after a config change like editing config/test.exs) showed it.

**Why:** struct patterns need the struct module at compile time, creating a cycle Router → Auth plug → User → Router.Helpers.

**How to apply:** In modules the router depends on (plugs like PanWeb.Auth), match on `%{field: value}` maps, not `%User{}`. After touching such modules, verify with `MIX_ENV=test mix compile --force`. Bisect by reverting single files from HEAD.
