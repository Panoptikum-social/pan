When upgrading to OTP 25+ (the project runs erlang 28.4.2 / elixir 1.19.5-otp-28), two common Erlang dep compile failures occur:

- **`gen_smtp` ≤ 1.2.0** — uses deprecated `crypto:start/0`; fix: bump to `~> 1.3` in mix.exs and run `mix deps.update gen_smtp`.
- **`mochiweb` ≤ 3.1.2** — uses `maybe` as an atom in tuples (`{maybe, X}`), which became a reserved keyword in OTP 25; fix: `mix deps.update mochiweb` (resolves to 3.3.0 within `html_sanitize_ex`'s `~> 3.1` constraint).

**Why:** Both are transitive deps that lagged OTP compatibility. The `maybe` keyword change was introduced in OTP 25 and is a hard syntax error in OTP 28.

**How to apply:** When a rebar3-compiled dep shows a syntax error with `maybe` or a `crypto:start` deprecation warning that blocks compilation, check for a newer version before patching.
