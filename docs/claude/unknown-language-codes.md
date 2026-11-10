`Pan.Parser.Language.get_or_insert/1` inserts every unknown `<language>` value as a new `languages` row with a UUID `name` and `"_ is missing"` emoji; such rows show up as "_ is missing <uuid>" in "Languages I speak" (Update Profile, grouped by `{name, emoji}` via `PanWeb.Language.grouped/0`).

**Decision 2026-11-04 (#496 dropped):** no parser change. New unknown codes are rare (none from 2026-09-29 to 2026-11-02 on the prod backup); the 34 from September came from un-retiring thousands of podcasts, which won't happen again. They were named by hand on prod 2026-10-31 via a console script; do the same if new ones appear.

**Why:** not worth code for a few rows a year.
**How to apply:** don't propose normalizing/skipping codes again unless the rate goes up; if "_ is missing" rows appear, offer a console snippet to name them. Options considered and declined: normalize to base code (`fr-MU` → `fr`), skip unknown codes, ISO 639 name table.

Data state 2026-11-04: 309 rows ≈ 70 real languages (English alone 59 rows, incl. junk like `Engli`, `© 2015`). Three picker defects found and dropped by decision (#559 `es-SP` emoji has a trailing space → second "Spanish" checkbox; #560 Catalan has two emojis → two checkboxes; #561 `ga` named "Galician" but is Irish).
