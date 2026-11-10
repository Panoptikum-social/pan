During the bounce-handling exploration (2026-09-21) the user said "don't change the backlog yet, i am still exploring" and later "bounce handling exploration is done from my side ... update the backlog" / "put it on the backlog". They also work strictly step by step ("one step after another", test in prod themselves, report back) and choose manual actions over automation (no marking job).

**Why:** premature backlog/code changes would record conclusions they had not reached.

**How to apply:** In an exploratory thread give findings and concrete next-step options, do not edit the backlog or build; wait for an explicit "update the backlog" / "do step N". Commit only when asked. See [no-invented-scope](no-invented-scope.md).
