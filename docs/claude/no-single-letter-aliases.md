User asked to change `alias Pan.Parser.Helpers, as: H` to `alias Pan.Parser.Helpers` (no `as:`) in `Pan.Updater.Podcast` and `Pan.Updater.RssFeed`, updating all `H.foo()` call sites to `Helpers.foo()` (2026-09-14, commit afc41e4b).

**Why:** a single-letter alias reads as noise at the call site — `H.to_255(...)` doesn't say what `H` is without checking the alias line; `Helpers.to_255(...)` is self-explanatory.

**How to apply:** don't introduce `as: <single letter>` aliases in new code in this codebase, and when touched incidentally, rename existing ones like it (`as: H`, `as: X`, etc.) to the plain full-module alias, updating call sites accordingly. Grep for `, as: [A-Z]\b` in lib/ if asked to sweep the whole codebase for more of these — this fix only touched the two files the user pointed at, not a full sweep.
