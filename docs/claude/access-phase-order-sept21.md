Decided 2026-09-21: access phase A (persona/gig-based check-feed access) is skipped. Order was: verification overhaul (done), then access phase B (next) (real podcast claiming). qa/prod verification of the Hex dependency is considered done.

Verification overhaul progress (same day):
- Step 1 rename email_confirmed → email_verified: committed 72acda6d (migration 20260921120000, deployed; JSON API field renamed too). Jekyll `pages/api.md` wording change left uncommitted in the Jekyll repo.
- Step 2 login block: DONE and committed 2026-09-21 (user tested the mail link end to end in dev via the new dev-only Dev Mailbox button on the admin dashboard). Unverified users can't log in by password (web + API), resend button after correct password (signed token, 1 h), signup no longer auto-logs-in (login_from_signup removed), any email-link login (verify or forgot-password) marks the address verified (in Auth.login_by_token). Existing sessions / remember-me cookies deliberately left alone.
- The verification overhaul is COMPLETE (user, 2026-09-21): the blocking + resend flow IS the "more standard / established" mechanism he meant; there is no separate step 3, don't propose one (token-based rewrite was my own unrequested idea). Token lifetime raised to 1 h (greylisting), committed e4fc13e0, DEPLOYED to prod and verified there by the user with a real new user (mail delivered, login blocked before verification, login works after), 2026-09-21.
- Existing unverified accounts (lock-out on deploy) are NOT a concern, user confirmed 2026-09-21; no count needed.

**Why:** User stopped me mid-question about phase A's access rule and chose to skip it.

**How to apply:** Don't start phase A. Next is access phase B (needs its own design discussion); see [feed-compliance-checker](feed-compliance-checker.md).
