On 2026-11-05 `mix` was "command not found" in the Bash tool; a piped `mix compile | grep error:` then looked like a clean compile.

**Why:** the tool's shell doesn't load asdf; a missing mix silently passes grep-filtered checks.
**How to apply:** start mix commands with `export PATH=$HOME/.asdf/shims:$PATH;` and check the exit status, not just empty grep output. Related: [compile-check](compile-check.md).
