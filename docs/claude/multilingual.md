Project #4 (started 2026-11-05): Panoptikum in English and German (Italian, French, Spanish maybe much later). Open items live in backlog.md (#600 German manual screenshots, #603 outdated qed start page).

**Done 2026-11-05** (commits dc660b57 groundwork + switcher, 748bde4b user setting, 1fff7af4 curation, 2c58b500 moderation, 895fe43b layout, aaeb2b4d account, 7918ada4 browsing, 08529451 podcaster tools, 8cbfb24a emails, e24edaee translated data + /admin/translations, 4748a31d roles, daed5e06 search by translated category titles); later the same day: 716d7a25 languages on My Profile/My Data/JSON (#595), 5fd60f72 persona links POST (#590), a18e6f38 moderation edit pages on moderation layout (#576), c4307528 admin sidebar/footer in user's language + footer no longer off screen (#596), 371f2d89 missed pad strings, b0b34a69 qed links per language (#586). Deployed step by step during the day (user deploys and checks along the way); search for "Kunst" verified on prod.

**Decisions (by the user):**
- Order curations → moderations → frontend. Admin ("backend") and the API stay English only.
- #563 locale = users.locale setting → "locale" cookie → Accept-Language → English; no URL prefix. Sign-up saves the page language as the setting (#583). users_languages (search filter picks) is NOT used as a default — dropped 2026-11-05: few entries, several picks give no single language, Accept-Language covers the first visit.
- #573 EN/DE switcher in the sidebar below the theme switcher; POST /locale without "Are you sure?" (OK by the user).
- #565 one gettext domain per phase: curation, moderation, frontend (errors + default for core components).
- Never translated: anything people write (podcast/episode data, communities, curation texts, pads, comments) — the audio stays in its language anyway.
- #574 moderation column/field labels (DB field names) stay English. #575 parser errors keep their English text inside translated wrapper sentences. #584 check_my_feed rule texts stay English. #586 qed links stay English until the qed pages are translated.
- Emails (#568, #583, #591, #592): login link + verification in the page language; retention notice in the user's setting; podcast claim in the podcast's language, persona claim in the persona's user setting or its podcasts' languages — exactly one supported language (region cut off) or English.
- #566/#567 translated data in a JSONB column keyed by locale; #585 small admin page for German category titles; #571 roles via gettext lookup with fallback; #569 search by translated category titles.
- #590 only: "Are you sure?" just for the deleting links (cancel delegation/redirect); the general rule #449 is unchanged.
- qed site (blog.panoptikum.social) got German pages (#597–#599, #602), see [jekyll-docs-repo](jekyll-docs-repo.md).
- German style: see [german-style](german-style.md). Don't invent scope: [no-invented-scope](no-invented-scope.md).

**Code map:** PanWeb.Translations (category_title/language_name by id from a persistent_term cache, role/1; refresh/0 after admin saves), /admin/translations (PanWeb.Live.Admin.Translations; Apple German category names + German language names prefilled by migration 20261105150000), Manticore categories.translations field. PanWeb.Locale (lib/pan_web/locale.ex: plug, on_mount :default/:english, from_language_codes/1), PanWeb.LocaleController, PanWeb.Component.LanguageToggle + assets/js/language_toggle.js, Podlove language in assets/js/app.js (subscribe button data-language) and assets/js/podlove_player.js (PLAYER_SET_LANGUAGE), tests in test/pan_web/locale_test.exs.

**Gotchas:**
- Before every commit that touches templates or LiveViews: `mix gettext.extract --check-up-to-date` (exit 0). Shifted line numbers alone make it fail; fix with `mix gettext.extract --merge`. Twice forgotten on 2026-11-05, each needed a follow-up commit.
- `import PanWeb.Gettext` does nothing with gettext 1.0 — use `use Gettext, backend: PanWeb.Gettext`.
- After `mix gettext.extract --merge`, fuzzy entries are wrong guesses (e.g. "Comment" → "Community"): clear them before translating.
- Text through `{dgettext(...)}` is HTML-escaped: no entities (`&amp;`, `&nbsp;`) in msgids; tests asserting apostrophes see `&#39;`.
- Admin pages force English via `on_mount {PanWeb.Locale, :english}` / `plug PanWeb.Locale, force: "en"`; the 3 moderation edit pages moved to `:moderation_live_view` (#576, 2026-11-05).
- Admin pages: content English, but sidebar/footer/switcher render in the user's language via `nav_locale` + `LayoutView.in_nav_locale/3` (#596, 2026-11-05); HEEx renders lazily, so partials are rendered to iodata inside `Gettext.with_locale`.
- Podlove web player 5.7.4 picks its language from the browser unless sent PLAYER_SET_LANGUAGE.

**Why:** the user wants the UI in more than one language.
**How to apply:** keep backlog.md to open items only ([backlog-only-open](backlog-only-open.md)); continue numbering from [numbered-lists](numbered-lists.md).

**2026-11-06:** #562 (Italian, French, Spanish) declined for now by the user, removed from backlog.md. German UI findings #611–#621 all done the same day (#618 via check_my_feed 0.6.0, #627).

**Closed 2026-11-06:** #618 done (check_my_feed 0.6.0), Project #4 block removed from backlog.md, nothing open. The user deploys Pan and publishes the qed versions (publish only after the deploy, the German podcaster manual says the rule texts are German).
