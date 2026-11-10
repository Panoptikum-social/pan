Markdown links in my replies only resolve relative to the workspace, so scratchpad files (/tmp/claude-1000/...) aren't clickable that way. The user found (2026-10-18) that a Read tool call on such a file is clickable in VSCode and opens it in a new tab.

**Why:** the user wants to look at analysis output lists themselves (e.g. candidate lists from tidewave Tasks).

**How to apply:** after writing an analysis result file to the scratchpad, Read it once so the user can open it; for short lists also paste them as a code block in the reply.
