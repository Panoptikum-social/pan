Access phase B = real podcast claiming. Design decided with the user 2026-09-21 (they described it, I did not invent it):

- **One user per podcast**: `podcasts.user_id` (nullable, FK users, nilify_all, indexed), schema `belongs_to(:owner, User, foreign_key: :user_id)`. NEVER cast from feed data; changes only via claim or admin. Once assigned, nothing changes automatically; disputes are decided by the admin (the user).
- **Owner email needs no new field**: owner = persona linked via engagement `role = "owner"`, email = `personas.email` (parser fills from itunes:email in itunes:owner, googleplay:email, plain owner/email).
- **Auto-assign** on opening `/my_podcasts` (UserFrontendController.my_podcasts): if user.email_verified, `Podcast.claim_by_owner_email/1` assigns all unassigned podcasts with matching owner email (case/trim-insensitive). **No cap** on shared hosting-provider addresses; user explicitly accepts that risk.
- **Manual claim**: button on podcast page mails a signed token to the owner persona email, copying the persona-claim flow (`persona_frontend_controller` claim/grant_access, `Pan.Email.confirm_persona_claim_link_html_email`); link assigns podcast to the logged-in user.
- **Admin UI**: easy assign / unassign / reassign of a podcast.
- **Check-feed gating**: `PanWeb.Live.Podcast.CheckFeed` only for the assigned owner, admins and moderators; hidden from everyone else (also hide the button in like_follow_subscribe_buttons.ex:104).
- Every assign/unassign/reassign goes into `PanWeb.Journal.log/1`.
- Claiming unlocks only check-my-feed for now; nothing extra goes in the backlog for that.

**Built 2026-09-21 (commit e5d26319, pushed and deployed), full suite + credo green:**
migration 20260921160000, `Podcast.claim_by_owner_email/1`, `owned_by/1`, `set_owner/3` (admin, journaled), `owner_admin_list/2`, `manageable_by?/2` (owner/admin/moderator), `feed_owner_emails/1`, `claim_token/2`, `verify_claim_token/2` (48h), `claim_by_confirmation/2`; `User.find_by_identifier/1`; admin LiveView `Live.Admin.Podcast.Owners` at /admin/podcasts/owners (route must live inside `live_session :admin`, else no current_user_id) + dashboard link; check-feed gated in `CheckFeed.mount` and button hidden; claim flow: POST /pan/podcasts/:id/claim mails owner address(es), GET/POST /podcasts/:id/grant_ownership approval page (POST so scanners can't approve), `Pan.Email.confirm_podcast_claim_link_html_email/4`; "Podcasts I manage" card on my_podcasts. Tests: podcast_claim_test, admin_podcast_owners_test, check_feed_access_test, podcast_claim_flow_test. backlog.md synced.

**Dev data facts:** 28,104 of 33,676 podcasts have an owner email; shared platform addresses (feeds@soundcloud.com 2488, audioboom 706 ...); 90 verified users match an owner email, biggest gets 5 podcasts.

**Open:** nothing; shipped and working in prod. Only the follow-up facts in backlog.md remain.

**Why:** backlog "Access phase B" (check-my-feed access control); user says "what doesn't get done goes into the backlog".

**How to apply:** treat as done. Extend only if the user raises follow-ups (see backlog.md). Related: [feed-compliance-checker](feed-compliance-checker.md), project_journal_and_entity_backfill, [exploring-vs-deciding](exploring-vs-deciding.md).
