Panoptikum used to have a paid "pro" user plan (delegation/redirect management for personas,
full persona-profile editing, extra features). It was never adopted, so it was fully retired on
2026-08-21, in incremental steps (each verified with a clean `mix compile --warnings-as-errors --force`
and format-check):

1. Router: merged `/pro` and `/jsonapi/pro` scopes into the existing `/pan`/`/jsonapi/pan` scopes,
   opening the routes to any `authenticate_user`/`authenticate_api_user` logged-in user instead of
   requiring `pro_until` in the future. Where two competing actions existed for the same route
   (`PersonaController.update` vs `pro_update`), the richer pro version won and the restrictive one
   was dropped — same pattern applied to `Persona.user_changeset` vs `pro_user_changeset` (pro version
   renamed to take over the plain name).
2. Removed dead `authenticate_pro`/`authenticate_api_pro_user` plugs and their entries in the
   `PanWeb` `only:` allowlists.
3. `live/persona/edit.ex` and `_personas.html.heex`: removed all `pro(@user)`-gated branches/UI —
   every logged-in user now gets full persona-edit/delegate/redirect capability.
4. `my_profile.html.heex`: removed the pro-status box (days-left banner, "Pro features"/"Payment
   information" links, billing fields) and the "currently on hold" message. Retired the now-orphaned
   `/pro_features` page and `/users/payment_info` page/route/action, and the `/go_pro` signup action.
5. Retired `Pan.Job.UserProExpiration` (a daily GenServer job registered in `config/prod.exs`/`qa.exs`
   that emailed users via `Pan.Email.pro_expiration_notification/1` when `pro_until` was about to
   lapse), and the admin "Unset Pro Date" button/action on the user admin page.
6. Removed `pro_until`, `billing_address`, `payment_reference`, `paper_bill` from the `User` schema,
   changesets, API/JSON-download views, admin databrowser naming, and the `my_data.html`/`edit.html`
   templates.
7. DB migration `20260821200757_drop_pro_plan_fields_from_users.exs` actually drops those four
   columns from `users` (reversible `remove/3` with explicit types; verified migrate/rollback/migrate
   on dev DB).

**Explicitly kept, on purpose**: the `Invoice` model, its uploads, and the invoice-download route/UI
(`InvoiceFrontendController`, the "My invoices" list in `my_profile.html.heex` and `my_data.html.heex`)
were deliberately left untouched — former pro users can still download their old invoices. Don't treat
Invoice as pro-plan leftover to clean up.

**Why:** the pro plan was never adopted by users, so the maintenance burden (branching UI, a dead
scheduled reminder job, unused billing fields) wasn't worth keeping. Full persona-management features
that used to be pro-only are now available to every logged-in user.

**How to apply:** if any future `grep -rn "pro_until\|pro_user_changeset\|authenticate_pro"` in this
repo turns up hits outside migrations/git history, that's regression, not intentional leftover.

**Leftover sweep (2026-08-21, post-migration)**: full repo scan confirmed clean — checked every
retired field/route/action name, whole-word `pro`/`pro_*` identifiers, marketing copy ("Panoptikum
Pro", "pro account", "go pro", "pro plan"), assets (JS/CSS), gettext/i18n, seeds/fixtures/tests,
sitemap/robots.txt, and mailer previews. Only hits are in `priv/repo/migrations/` (the two 2017
migrations that added the columns and the 2026-08-21 one that drops them) — expected and correct,
migration history stays immutable.
