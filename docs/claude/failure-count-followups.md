Failing-podcast series #35–#52 is closed (deployed 2026-10-02; key commits 57728daf retire at `>= 10`, 92b60d6d redirect persistence fix, 7c0567c5 restore of 220 overwritten feed URLs, d2687687 307 handling). Podbean pbcdn1 URLs rewritten to feed.podbean.com.

Decisions worth keeping:
- Retirement: `Pan.Updater.Podcast` retires when the new failure_count is `>= 10` (nil-safe); test in test/pan/updater/retirement_test.exs.
- Maintenance stats "retirement candidates" counts `failure_count >= 9` and not retired (0b4f60ee, 2026-10-10); prod showed 36 candidates afterwards, which the user is happy with.
- User-Agent blocks (qurancentral, muslimcentral etc.): no workaround, never spoof a browser UA; they just retire.
- Unchanged feed ("nothing to do") resets failure_count like a successful import.

Related open item: duplicate-title metadata refresh, see [podcast-title-clash](podcast-title-clash.md) (now in backlog.md).

**Why:** user confirmed on 2026-10-10 that retirement works as intended.

**How to apply:** treat retirement as settled; don't reopen unless the user brings it up.
