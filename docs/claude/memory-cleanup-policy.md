Applies to the knowledge files in docs/claude/ (until 2026-11-10 they were Claude's local memory files; `project_*` = the project notes, `feedback_*` = the working rules).

2026-09-22: user asked to "remove all closed items" from the memory index. Clarified scope first (just the one just-closed item, vs. all finished/shipped project memories) — user chose the broad sweep. Removed 52 files total across two passes (49 in the main `MEMORY.md`-indexed sweep, 3 more found in a second pass over files that existed on disk but were never added to the index).

**Heuristic applied — DELETE a `project_*` memory when:**
- It records a completed/deployed/shipped/fixed/committed task, especially one citing a specific git commit hash (redundant with `git log`).
- It's a "won't fix" / "rejected" / "dropped" decision with no follow-up action attached.
- It's a duplicate of another kept memory (e.g. two separate project-overview-style files that had drifted apart).

**KEEP a `project_*` memory even if it looks like a closed task, when:**
- It has an explicit unresolved thread ("not yet run", "not done", "pending", "still open") that isn't already tracked in `backlog.md` — check `backlog.md` before deleting anything claiming "follow-ups are in the backlog."
- It documents a deliberately accepted gap/limitation in current behavior (e.g. "no cascade delete to child records, user accepted this") — this explains a non-obvious *current* state, not a finished task.
- It's a roadmap/backlog-style item describing future work, not past work.
- It's an investigation that corrected an earlier wrong claim — deleting it risks silently repeating the same wrong theory later (verification memories pay for themselves by avoiding re-derivation, per [verify-before-theorizing](verify-before-theorizing.md)).

**Always keep:** `feedback_*` memories (standing behavioral rules, not task status) and pure reference/pointer facts (asset locations, docs-repo location, fixture accounts) — these aren't "closed," they don't expire.

**Bonus finding from the second pass:** always read orphaned/unindexed memory files before discarding them — one (`feedback_elixir_patterns.md`) contained stale advice that directly contradicted a *different*, correct, still-indexed memory (`feedback_byte_safe_truncation.md`) and contradicted the actual current code. Cross-check contradictory-sounding memories against the real code before trusting either.

**Why:** avoid re-litigating scope and re-deriving the same closed/open judgment calls next time a cleanup is requested.

**How to apply:** when asked to prune memory again, apply this heuristic directly rather than asking scope questions from scratch, unless the request is ambiguous in a new way.
