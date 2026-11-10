Also tracked in backlog.md (item "Dark-mode screenshots for the Listener and Podcaster Manual"); keep both in sync.

Started 2026-10-31: replace the outdated screenshots in `pages/manuals/listener-manual.md` and
`pages/manuals/podcaster-manual.md` of the qed site (see [jekyll-docs-repo](jekyll-docs-repo.md)) with
current ones in dark mode (Catppuccin Mocha). Decisions (numbering, see [numbered-lists](numbered-lists.md)):
- #486 new file names, only the manuals point to them; old 2016–2018 blog posts keep the old images.
- #487 taken on the dev server (localhost:4000) with headless Chrome (playwright-core 1.55.0,
  `executablePath: /usr/bin/google-chrome`, `colorScheme: "dark"`), user OK'd changing dev data.
- #488 screenshots of removed/changed features (Podlove 5.7.4 dialogs, Twitter/Facebook share,
  mail client, withdraw tooltip) → numbered list for the user to decide; no text edits without OK.
- #489 a demo user, not a real account. Two friends of the user may appear in shots, they agreed (2026-10-31).

Recipe: scripts in `/daten/DATA/phoenix/pan-assets/manual-screenshots/` (`lib.mjs` = session
login via `/sessions/login_via_token?token=` + `PanWeb.Auth.sign_token(:link, user_id)` from
tidewave, token valid 1 h; hides `#tidewave-toolbar` and the DEV badge, clicks the cookie "I
agree", accepts confirm dialogs, `fixHost` rewrites localhost permalinks to panoptikum.social;
main column clip x=288). `npm install` there first. Finished images: `done-2026-10-31/` (10).

The dev DB restore of 2026-11-01 wipes the demo data, recreate: user `demo` ("Demo Podcaster",
demo@example.com, podcaster, email_verified, share both); logging in auto-creates persona "Demo
Podcaster"; extra personas "D. Podcaster" (no email) and "Demo Co-Host"
(demo-cohost@example.com) + "Demo und Co-Host", gigs/engagements on Aua-uff-Code! (podcast 104,
5 latest episodes). Then: claim D. Podcaster (warning → Claim), claim Demo Co-Host by email
(mail in /dev/mailbox, open its grant link), claim contribution on episode 6206480.

Done 2026-10-31 (second session, shots in `raw/`): Edit persona before/after (pid demo-podcaster, image
saved), delegations D. Podcaster + Demo Co-Host → Demo Podcaster (GET
`/pan/personas/<id>/toggle_delegation?delegate_id=239492`, links hidden while the entry is collapsed),
profile with all entries expanded, public persona page (retaken after the #491 and #497 fixes). `lib.mjs` now routes
`https://panoptikum.social/thumbnails/**` to `/var/phoenix/pan-uploads/images/**` (the page always loads
thumbnails from prod, so images uploaded on dev were broken).

Claim-request shots done too (raw/claim-panel, claim-request-mail; #501 b: no shots of the email-sent and grant pages, describe them in the text): extra demo
persona "Demo Guest" (id 239493, demo-guest@example.com, gig on episode 6206480), claimed by demo and
granted via the mail; afterwards its gig and the manifestation were removed again, so the episode page shows
only the three original claim buttons (recreate it only to retake the claim shots). The mailbox page needs the HIDE style too
(`shot` adds it). #500 claim wording made gender-neutral, shots retaken.

After #491/#497/#500 the outdated finished shots were retaken (add/added-contribution, persona-without-email
on "Demo und Co-Host" since D. Podcaster is claimed now, metadata-update); claim-persona.png dropped, raw/claim-panel.png
replaces it. Listener: raw/recommend-form.png + raw/recommendation-buttons.png (tweet/mail buttons; Facebook gone).
Old→new mapping: claim-email.png → none (#501 b), claim-request → claim-request-mail, myprofile-pro1 →
profile-persona-expanded, edit-persona1/2 → edit-persona-1/2, persona-waldgruber → persona-public,
persona-sms/ss/s → persona-entry-0/1/2, mydata → user-menu. Text still describes the old UI in places
(Claim "below the gigs table", user menu "in the header").

Finished 2026-10-31: 24 images imported into the qed site as `manual-*.png` (prefix because 5 old names
are still used by 2017 blog posts), both manuals rewritten for the images, build clean, version saved
("Manuals: new dark-mode screenshots, ..."). Publishing is the user's step in the app. #508 My Messages section removed (gone from the app),
#509 Edit persona field list updated (Description = heading, Long description = markdown, Fediverse panel is off),
#510 walkthrough retold with the demo user (claim panel retaken on Demo Co-Host as manual-claim-panel-2.png;
the Demo Guest version deleted); second version saved. lib.mjs also routes `localhost:4000/thumbnails/**` (My Profile uses relative paths) and
sets `locale: "en-US"` (Podlove player follows the browser language).

Findings: #490 languages with UUID names (fixed on prod 2026-10-31 by console script, root cause #496 in backlog.md), #491 persona page
avatar overlaps the Claiming panel (fixed 2026-10-31), #497 outline-button icon colors (fixed), #492 My Profile persona entry layout and #493 Edit
persona required Uri — both fixed 2026-10-31 in 16d5e143 (not yet deployed). Backlog items
committed in c807cf97 (#491, #496, this project).

Gotchas from the first run: Claim links are POST + "Are you sure?" confirm (headless Chrome
dismisses dialogs unless accepted); the edit form has two submit buttons (use
`button.btn-info[type=submit]`); dev mail HTML at `/dev/mailbox/<id>/html`, grant link inside
points to localhost; the app's inner scroll container means `fullPage` screenshots stop at the
viewport height — set a taller viewport instead; the Write hook runs `mix format
--check-formatted` on any written .exs, scratchpad files included.

**Moderator + Curator Manual (2026-10-31):** new pages `pages/manuals/moderator-manual.md` (weight 30)
and `curator-manual.md` (weight 40), text only, written from the code (routes /moderator, /curator,
moderation grid labels, pad and curator assignment UI); /manuals got a section for each; version saved.
#511 contact is sonja@ (user). #512 screenshots taken 2026-10-31
(manual-mod-*/manual-cur-*.png, 15 images, scripts batch18-20): demo user (6002) is moderator + curator of
Wisspod (community 1, slug wisspod, category 106, heading shows "Wissenschaftspodcasts.de"), follows it,
3 example curations (53032 recommended, 53053 rather_recommended, 53044 indifferent, text "*Example for the
manual:* ..."), pad "Manual demo pad". Curator shots were taken with moderator flag + moderation row removed.
Privacy: 7 real curations sit on open podcasts — search "Podcast"/"Digital" avoids them; curators page
(real usernames) and API errors (empty on dev) held back, asked as #514/#515. #513 fixed "open – mark done"
wrapping (whitespace-nowrap in curation/community.ex). Menu: site.toml main_menu.items hand-arranged.

**Resume here (end of session 2026-10-31):** open items are in backlog.md: #514 curators-page shot, #515
API-errors shot (a/b/c), deploy pending (5f084341, 4fcc112e, 8720da6b, d3fd7ce4 unpushed; backlog.md
change itself uncommitted at session end). All four manuals are written and saved as qed versions; the
user publishes from the q.e.d. app (publishing carries all texts and media). The dev restore of
2026-11-01 wipes the demo data: recreate it from the recipes above before any retake (user demo,
personas, claims, delegations, persona edit; then moderator+curator of Wisspod, follow, curations, pad).

**Published 2026-10-31** by the user, who was happy with the result ("so much better than before").
**Deployed 2026-11-01:** the user deployed all four app commits (#491/#497, #499, #500, #513) to prod; main pushed to gitea.

**2026-11-03:** #515 done with option c: the user took the API errors page on prod; Claude blurred podcast names/IDs (Podcast column + names in the merged-podcast error texts) with ImageMagick `-region … -blur`, cropped the sidebar off, imported as manual-mod-api-errors.png into the Moderator Manual's API Errors section, version saved (publishing is the user's). Source + result in ../pan-assets/handover/. #514 done the same day: user's prod shot of the curators page, names NOT blurred (user: the curators are good friends and public podcasters, OK to show), sidebar cropped, manual-mod-curators.png in the Curators section, version saved. Backlog item removed; all manual screenshot items closed.

**2026-11-03 retake setup (after the dev restore):** user `demo` recreated as id 6003 via `User.changeset/2` + `put_change(:password, ..)` + `User.put_pass_hash/1` + `email_verified: true` (`registration_changeset` needs password_confirmation and the bot check, which just wants "42"). Token login (`/sessions/login_via_token`) does NOT create the user persona: call `Persona.create_user_persona(user |> Repo.preload(:user_personas))` (persona 239828). Demo data: subscriptions 104, 84, 93, 31, 434, 26; likes 104, 84, 434; follows 104, 93; podcast 104 assigned to demo (user_id) after taking the Claim-button shot. Manticore on dev may be stopped (systemd `manticore`, disabled) — the user starts it. Paths: My Podcasts `/pan/my_podcasts`, My Data `/pan/my_data`, Check feed `/pan/podcasts/104/check_feed`. Script `batch21.mjs` (phases out/claim/search/owner), finished shots in `done-2026-11-03/` (11, `manual-lis-*`, `manual-pod-*`), imported and placed in both manuals, version saved. Sign-up shot held back: #538 (form shows an error on first render).

**State at end of 2026-11-03:** listener + podcaster manual text review (#521–#534) and all screenshots (#514/#515/#535/#536, incl. sign-up after the #538 fix) done and saved as qed versions; the user published the moderator shots, the later versions (text review, 12 shots) may still be unpublished — ask. Nothing about the manuals is left in backlog.md. App commits of the day (557c6aa0, db6fd018, ee6810cc) deployed and checked on prod.

**German screenshots (#600, 2026-11-06):** `SHOT_LANG=de` in lib.mjs → browser de-DE (app + Podlove follow it), clicks "Einverstanden", every `raw/…` goes to `raw-de/…`. Script `de.mjs <token> <phase>`, phases in order: pre, claim, persona, (DB delegations), entries, podlove, recommend, signup, owner (after `podcasts.user_id = 6003` for 104), search (needs Manticore), curator, moderator, pad. Demo data recreated after the restore: user demo id 6003 (`locale: "de"`), persona 239861 → pid demo-podcaster; D. Podcaster 239862, Demo Co-Host 239863 (demo-cohost@example.com), Demo und Co-Host 239864 (author), each with gigs on the 5 latest episodes of 104; retired example now podcast 12310 (9751 is gone). Main column is now x=290/width 990 (rainbow sidebar line). Podlove iframe sometimes loads at 313 px → resize the viewport once (#616; known to the user, it corrects itself a bit later in real browsers, not a bug). Pad for the shots: "Podcast-Archivierung" in Wisspod (user's idea), content about archiving difficulties written via `PadServer.restore/2`; raw-de/pad-view.png taken but not used yet. 51 images imported as `media/manual-*-de.png`, only the `.de.md` manuals point to them, version saved. The two prod shots (API errors blurred, curators unblurred) were taken by the user in German 2026-11-06 (they land in ~/Bilder, not handover; copies in ../pan-assets/handover/): all 53 German shots done, #600 closed. UI findings #611–#621 in backlog.md.
