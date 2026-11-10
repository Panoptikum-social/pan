`<td class="flex flex-wrap gap-1">` in the curator overview turned the cell into a flex box that ended at its own content height; the user noticed the column looked shorter than the others (fixed in d074973c).

**Why:** `display: flex` replaces `display: table-cell`. It's invisible when that cell is the tallest in the row (the top-list table in `_wide_top_list_table.html.heex` keeps the pattern harmlessly, user agreed to leave it), visible when it's shorter.
**How to apply:** for wrapping badges/buttons in a table cell, use `<td><div class="flex flex-wrap gap-1">…</div></td>`.
