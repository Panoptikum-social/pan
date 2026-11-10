The dev database is a prod backup, usually restored from the previous night (stated 2026-10-02).

**Why:** data findings in dev (retirement reasons, error messages, counts) are real prod history, not dev artifacts.

**How to apply:** treat dev DB rows as prod evidence when investigating; only today's changes since the backup are missing. Use tidewave for queries ([use-tidewave-for-db](use-tidewave-for-db.md)).
