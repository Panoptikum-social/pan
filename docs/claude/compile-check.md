Always use `mix compile 2>&1 | grep -iE "error|exception"` (case-insensitive, no colon, no head limit) when checking compilation results.

**Why:** `mix compile` can report failures as `** (SomeException)` (no colon, mixed case) or plain `error:` lines, and errors can appear anywhere in the output — grepping only for `"error:"` with a colon or truncating with `head` misses these.

**How to apply:** Every time after editing a file and running mix compile, use the grep pattern above.
