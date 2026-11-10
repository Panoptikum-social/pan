When debugging runtime errors from the Surface → Phoenix component migration, consult the git history first:

```
git log --oneline -- <file>
git show <commit> -- <file>
```

The working Surface implementation shows the intended prop/assign structure. Compare it to the current Phoenix version to spot what was dropped or wired up incorrectly.

**Why:** The Surface components were working correctly. Migration bugs are typically dropped `attr`/`slot` declarations, misplaced declarations, or missing assigns that the Surface framework handled automatically.

**How to apply:** Before reaching for defensive `assign_new` workarounds, diff the old Surface version against the new Phoenix version to find the root cause.
