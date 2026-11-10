When `mix format` (run on the whole project) also reformats files unrelated to the current change, the user is fine with it ("I appreciate it") and wants them committed.

**Why:** the user said so on 2026-11-04 after I tried to revert such changes (which the auto-mode check blocked anyway).
**How to apply:** don't revert formatter changes in other files; leave them out of the feature commit and commit them separately with the message "mix format".
