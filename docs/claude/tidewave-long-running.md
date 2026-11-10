`mcp__tidewave__project_eval` gives up after 30 seconds. On 2026-10-01 a cleanup kept running inside the dev server after the call timed out, so it had partly happened before I noticed. The working pattern, used for the ~1h40m dev re-index:

1. Start the work in `Task.start(fn -> ... end)` inside the eval, and record steps (e.g. in `:persistent_term`) with try/rescue around them.
2. In a second Task, write the progress (steps plus a count) to a file in the scratchpad every ~60 s, and a final marker such as `FINISHED` or the error.
3. Wait with Bash `run_in_background` and `until grep -q FINISHED file; do sleep 30; done`. You get one notification when it ends. Check progress in between by reading the file.

Large counts, like over episodes, also exceed 30 s. Run them the same way, or write the result to a file.

**Why:** a timed-out eval looks like a failure while the work continues in the server, which leads to wrong conclusions about the results (a misread orphan count on 2026-10-01).
**How to apply:** for anything that might take more than ~20 s in dev (resets, re-indexes, full-table counts), use the Task + file + background-wait pattern from the start. Related: [use-tidewave-for-db](use-tidewave-for-db.md)
