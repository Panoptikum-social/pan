Built and deployed to prod 2026-10-01. Commits: f83af79c (feature), 1b36086f (OverType for personas, GFM markdown without images), 0bb21668 (moderators make curators), 9c6e31d7 (ProcessWire data migration + community card counts), 14fc5576 (feed matching fix, see [feed-url-matching](feed-url-matching.md)), d074973c (grades cell fix).

Decisions:
- `users.curator` boolean. Admins set/clear it; moderators may only *set* it, in one step with assigning, by exact username on `/moderator/curators` (Q46–48, `Curatorship.make_curator_and_assign/2`). Excluded from retention tooling like admins/moderators.
- `curatorships(user_id, community_id)`: only flagged users assignable. Admins via `/admin/communities/curators` (all), moderators via `/moderator/curators` (own communities only, may also remove). Removing keeps curations.
- `/curator` scope guarded by `authenticate_curator` plug = curator || moderator || admin (Q37 b); `Curation.permissions/2` applies the same gate, so leftover curatorships of a user without flag/role give nothing.
- `curations`: 0..1 per curator × podcast × community; markdown + grade enum. Only author edits, overwrite, **no deleting** (decided). user deleted → user_id nilified ("former curator"); podcast/community deleted → curations deleted.
- Read: community's curators + moderators, admins all. Never public/podcasters. Out of Manticore and API (maybe pushed to third parties later).
- `categories_podcasts.open_for_curation`: rows existing at the migration false, new rows true (schema default too), so an open row not in the hand-picked list = linked after the deploy. Toggled only in curator overview (filter open/done/all + title search for mods/admins; curators see open only).
- Start page is `/curator/my_curations`, see [persona-catch-all-route](persona-catch-all-route.md).
- OverType 2.5.0 self-hosted in `priv/static/overtype/` (+LICENSE), lazy-loaded by `OvertypeField` hook; curations and persona long descriptions. SimpleMDE removed.
- Markdown for both via `PanWeb.ViewHelpers.markdown/1`: MDEx with table/strikethrough/autolink, `HtmlSanitizeEx.Scrubber.MarkdownWithoutImages` (images → alt text, user decision: no third-party loads).
- Curation boxes on podcast page: `rounded-box border border-base-content/20 bg-base-300 p-4` (user approved contrast).
- `/communities` cards show podcasts (non-blocked), contributors (formerly "members"), followers, moderators, curators, pluralised with Inflex.
- Data migration 20261001130000 added the 426 ProcessWire (wissenschaftspodcasts.de, field `podcast_panoptikum_id`) podcasts to community 106 closed + 23 hand-picked open (dev 267→492).

**Why:** curations are input for third-party platforms; a podcast can be graded differently per community.
**How to apply:** ask before deviating from these decisions; open-question numbering in that session reached 69.
