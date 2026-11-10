When the user pastes exception-notification mails (prod Logger backend mails every :error entry), many are days old and from earlier deployments. Before proposing a fix, check whether the stack's file:line still matches the current code (`git log -S`/`-L` to find the fixing commit) and say "already fixed by <sha>" when so. Low pids (0.3xxx) = shortly after a node start; the job pids are stable per boot (ImportStalePodcasts ≈ 0.3565, PushMissingSearchIndex ≈ 0.3568).

**Why:** in the 2026-10-18 pass about a third of the mails were duplicates or pre-fix (tuple probe errors fixed 1ddf462c, HTTP/2 GOAWAY gone since bcc91098, podbean killed-conn pairs). The user groups related mails and asks "same one?" — answer by matching the evidence, briefly.

**How to apply:** propose numbered options with a recommendation and wait for the pick (see [numbered-lists](numbered-lists.md)); the user often chooses the minimal fix (e.g. add one HTML entity, not a generic decoder) or "leave it as is". Known causes:
- raw xmerl lines "N- fatal: reason" carry no podcast id; reproduce the reason with `:xmerl_scan.string` via tidewave, then either pre-clean in `Helpers.fix_html_entities/1` or silence in `Pan.LoggerFilters`.
- Unknown HTTP status → `Download.download/1` logs "status_code unknown" and returns :ok → WithClauseError in the updater; add the code to the list + `@error_map` (see [download-unknown-status-log](download-unknown-status-log.md)).
- hackney 4.8.5 `safe_call` doesn't convert `killed` exits; `Download.request/3` catches exits since 3eeec04d.
- OTP 28 ssl ticket store TryClauseError on concurrent TLS 1.3 handshakes: accepted until OTP 29 (backlog.md).
- `{:invalid_name, ~c"…"}` from xmerl = a stray "<" in text: whitespace after it (#170) or ">" after it (#480, "A <> B") are escaped by `Helpers.escape_stray_less_thans/1`; reproduce with plain `elixir -e ':xmerl_scan.string(...)'` (no app, no DB needed).
- `"value too long for type character varying(255)"` on podcasts.last_error_message: gone since b9b1516b (column is text, #473). Long TLS texts (bad_certificate with host names) are wanted in full.
- `Manticore bulk insert request failed … :checkout_timeout`: shared hackney default pool busy; handled, retried next PushMissingSearchIndex run — leave it (#477).
- A podcast behind an ImportStalePodcasts crash: the last `<id> ⬇ <title>` line before the crash in `journalctl -t pan --since "-5 days" | grep -B40 "crashed" | grep -E "⬇|crashed"`.
