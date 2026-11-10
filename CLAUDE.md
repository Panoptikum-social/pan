# Panoptikum: project knowledge for Claude

This file and [docs/claude/](docs/claude/) hold everything Claude has learned about this project (moved here from Claude's local memory on 2026-11-10). **Save new learnings here, not in local memory:** a short rule in this file, details in a `docs/claude/<topic>.md` file listed in the index below. Commit these changes like any other change. Never write IP addresses, private hostnames or names of private people into these files (the repo is public).

Panoptikum is a podcast discovery platform (panoptikum.social): OTP app `pan`, Elixir/Phoenix 1.8/Postgres, LiveView-heavy, Manticore for search. Domain logic in `lib/pan/` (parser, updater, search, jobs, mailer), web layer in `lib/pan_web/`. See [overview](docs/claude/overview.md).

## Working with the user

- **Number** findings, options and open items, and keep the numbering going across sessions. **Next new number: #628.** History: [numbered-lists](docs/claude/numbered-lists.md). Update the next number here when you use new ones.
- While the user is "still exploring", only investigate and answer. Edit the backlog or code only on an explicit request. Go step by step; the user prefers manual over automatic ([exploring-vs-deciding](docs/claude/exploring-vs-deciding.md)).
- Don't put your own ideas into backlog items or summaries as if they were decided. Ask when the wording is vague ([no-invented-scope](docs/claude/no-invented-scope.md)).
- [backlog.md](backlog.md) holds only open work. Delete finished items and put reference knowledge into docs/claude ([backlog-md-sync](docs/claude/backlog-md-sync.md), [backlog-only-open](docs/claude/backlog-only-open.md)). Cleanups noticed during other work become a numbered backlog item; the user decides later ([cleanup-findings-to-backlog](docs/claude/cleanup-findings-to-backlog.md)).
- Commit only when asked. Never amend a commit after telling the user to push it ([no-amend-after-handoff](docs/claude/no-amend-after-handoff.md)). The user pushes and deploys on their own, often several times a day: never claim commits are undeployed; say what a deploy of them needs ([user-deploys-incrementally](docs/claude/user-deploys-incrementally.md)).
- Unrelated `mix format` changes are welcome: commit them separately as "mix format" ([mix-format-whole-project](docs/claude/mix-format-whole-project.md)).
- Before proposing a root cause, query the real timestamped data (dev DB = prod backup) ([verify-before-theorizing](docs/claude/verify-before-theorizing.md)). Prod DNS is never the suspect.
- Prod error mails are often from older deployments: match line numbers to the current code first ([error-mail-triage](docs/claude/error-mail-triage.md)).
- Renders and synthetic clicks don't prove that third-party widgets (Podlove, OverType) work: ask for real clicks and playback ([real-clicks-third-party-ui](docs/claude/real-clicks-third-party-ui.md)).
- To show a scratchpad file, Read it: the Read call is clickable in the user's VSCode ([show-scratchpad-files](docs/claude/show-scratchpad-files.md)).
- Write "Panoptikum" in text, "panoptikum.social" only as a link or address ([panoptikum-name](docs/claude/panoptikum-name.md)).
- German UI: "Sie", colon gender form (Kurator:in), claim = "übernehmen"/"Verwaltung beantragen", never "beanspruchen"; "Communities" stays English ([german-style](docs/claude/german-style.md)).
- Pruning these notes: [memory-cleanup-policy](docs/claude/memory-cleanup-policy.md).

## Hard rules

- **Never make parallel outbound requests.** Sequential only; parallel requests got prod blocked ([no-parallel-outbound-probes](docs/claude/no-parallel-outbound-probes.md)).
- Data-changing routes are POST (the API too) and their buttons ask "Are you sure?" ([mutating-actions-post-confirm](docs/claude/mutating-actions-post-confirm.md)).
- Integer-id show routes: 404 via `PanWeb.PathId.to_integer!/2` + `Ecto.NoResultsError`, standard "404 Not Found" page. Dev shows the debug page instead (`debug_errors: true`), so say so upfront ([path-id-404](docs/claude/path-id-404.md), [dev-debug-errors-404](docs/claude/dev-debug-errors-404.md)).
- External URLs in `<.link href>` go through `safe_href/1` + `safe_uri?/1`: LiveView's scheme check is case-sensitive and raises ([link-href-safe-href](docs/claude/link-href-safe-href.md)).
- Don't re-gate cached-asset regeneration on "the source URL is unchanged" ([thumbnail-cache-invalidation](docs/claude/thumbnail-cache-invalidation.md)).
- Prod Postgres session time zone isn't UTC: no bare SQL `now()` into naive columns; pass `NaiveDateTime.utc_now()`, cast `$1::timestamp` ([sql-now-timezone](docs/claude/sql-now-timezone.md)).
- Prod console snippets get pasted into IEx: no line-leading `|>` after an assignment, keep a dry_run switch, test them on dev first ([iex-paste-safe-snippets](docs/claude/iex-paste-safe-snippets.md)).
- Run `mix hex.audit` and `cd assets && npm audit` unasked whenever deps are touched or a deploy is prepared ([hex-audit](docs/claude/hex-audit.md)). Run `mix sobelow` after security-relevant changes; any output is new ([sobelow](docs/claude/sobelow.md)).

## Tools and environment

- Bash: start mix commands with `export PATH=$HOME/.asdf/shims:$PATH;` and check the exit status, since empty grep output is not a clean compile. Check compiles with `mix compile 2>&1 | grep -iE "error|exception"` ([mix-path](docs/claude/mix-path.md), [compile-check](docs/claude/compile-check.md)).
- Use tidewave for DB inspection and evals. If it's unavailable, ask the user: no ad-hoc `mix run`/psql ([use-tidewave-for-db](docs/claude/use-tidewave-for-db.md)). Evals time out at 30 s: long jobs via Task + progress file + a background until-loop ([tidewave-long-running](docs/claude/tidewave-long-running.md)).
- The dev DB is a restored prod backup (usually last night): its data is prod evidence ([dev-db-prod-backup](docs/claude/dev-db-prod-backup.md)). Six background jobs run on prod only, none in dev ([dev-background-jobs-disabled](docs/claude/dev-background-jobs-disabled.md)).
- IDE markers can lag behind: trust fresh `mix credo`/compile. An ElixirLS dep error on mix.exs while the CLI is fine → delete `.elixir_ls/` and restart ([stale-ide-diagnostics](docs/claude/stale-ide-diagnostics.md), [elixir-ls-stale-build](docs/claude/elixir-ls-stale-build.md)).
- Only prod sends real mail; dev mailbox at /dev/mailbox ([mail-delivery-envs](docs/claude/mail-delivery-envs.md)). `/var/phoenix/pan-uploads/` must be created by hand on dev machines ([upload-directory](docs/claude/upload-directory.md)).
- QA Docker runs on the user's home server, port 4001, never via qa.panoptikum.social (HSTS) ([qa-home-server](docs/claude/qa-home-server.md)). Prod builds the release itself: esbuild bump needs `mix deps.get` then `mix esbuild.install`; `npm install` when package.json changed ([prod-deploy-esbuild](docs/claude/prod-deploy-esbuild.md)).
- Docs, blog and manuals are the qed site in `/daten/DATA/rust/sites/blog.panoptikum.social` (MCP server `qed-panoptikum-social`; publishing is the user's step; the running MCP server locks the site against the desktop app) ([jekyll-docs-repo](docs/claude/jekyll-docs-repo.md), [blog-posts](docs/claude/blog-posts.md), [manual-screenshots](docs/claude/manual-screenshots.md)).
- Pads: edit the dev pad through PadServer for browser checks ([pad-server-side-test-edits](docs/claude/pad-server-side-test-edits.md)).

## Code conventions and gotchas

- Admin LiveViews: `use PanWeb, :admin_live_view` ([admin-layout](docs/claude/admin-layout.md)).
- `attr`/`slot` declarations go immediately before their component function ([attr-placement](docs/claude/attr-placement.md)).
- Live components: `<.live_component module={M} id="...">`, never `M.render` ([live-component-call-syntax](docs/claude/live-component-call-syntax.md)). Every `phx-click`/`phx-change`/`phx-submit` inside one needs `phx-target={@myself}` ([phx-target-myself](docs/claude/phx-target-myself.md)).
- `stream/3` resets by default: `reset: false` + a `has_more` guard for load-more ([stream-infinite-scroll](docs/claude/stream-infinite-scroll.md)).
- `<.button>` without `class=` is a muted `btn-soft`: always pass `class="btn btn-primary"` or similar ([core-components-button](docs/claude/core-components-button.md)). DaisyUI v5 conventions: [daisy-ui-migration](docs/claude/daisy-ui-migration.md). Never `flex` on a `<td>`: wrap the content in an inner div ([no-flex-on-td](docs/claude/no-flex-on-td.md)). Design language: [DESIGN.md](DESIGN.md), the reasons behind it: [catppuccin-themes](docs/claude/catppuccin-themes.md).
- Inline scripts need `nonce={@csp_nonce}`; `'unsafe-eval'` must stay for Podlove; Alpine is the CSP build ([content-security-policy](docs/claude/content-security-policy.md)).
- `%{}` matches all maps: catch-all clauses go last ([elixir-patterns](docs/claude/elixir-patterns.md)). `Map.get/3`'s default doesn't apply to nil values ([map-get-nil-default](docs/claude/map-get-nil-default.md)).
- No single-letter module aliases ([no-single-letter-aliases](docs/claude/no-single-letter-aliases.md)). Prefer extra function clauses over single-call private helpers ([avoid-single-use-helper](docs/claude/avoid-single-use-helper.md)).
- In modules the router depends on (PanWeb.Auth), match plain maps, not `%User{}`: it deadlocks a full compile ([struct-pattern-compile-deadlock](docs/claude/struct-pattern-compile-deadlock.md)).
- DB foreign keys are `on_delete: :nothing`: check for uncovered references before `Repo.delete!` ([ecto-on-delete-gotcha](docs/claude/ecto-on-delete-gotcha.md)).
- Truncate to byte-limited columns by byte slicing (`to_255/1`), not by character count ([byte-safe-truncation](docs/claude/byte-safe-truncation.md)).
- Custom HTML scrubbers: `use HtmlSanitizeEx, extend: :strip_tags` ([html-sanitize-ex-scrubber](docs/claude/html-sanitize-ex-scrubber.md)).
- The "status_code unknown" log in Download is intentional: just add new codes to the map ([download-unknown-status-log](docs/claude/download-unknown-status-log.md)).
- The `/:pid` persona route swallows one-segment paths: give new areas sub-path start pages ([persona-catch-all-route](docs/claude/persona-catch-all-route.md)).
- Before committing template/LiveView changes: `mix gettext.extract --check-up-to-date` ([multilingual](docs/claude/multilingual.md)).
- Phoenix 1.8 legacy view lookup ([phoenix18-controller-formats](docs/claude/phoenix18-controller-formats.md)). Leftovers of the Surface migration: [runtime-errors](docs/claude/runtime-errors.md), [surface-hooks-migration](docs/claude/surface-hooks-migration.md), [surface-prop-defaults](docs/claude/surface-prop-defaults.md).

## Knowledge index (docs/claude/)

**Feeds, parser, updater**
- [parser-hardening-sprint-sept14](docs/claude/parser-hardening-sprint-sept14.md): parser fixes and which Quinn errors are noise, not bugs
- [helpers-tests](docs/claude/helpers-tests.md): parser regression tests; UTC offsets dropped by design; unknown tags skipped silently
- [parser-extraction-roadmap](docs/claude/parser-extraction-roadmap.md): Project #1 closed: parser core isolated, package extraction declined
- [feed-redirect-loop-design](docs/claude/feed-redirect-loop-design.md): what "loop detected" means; alternate_feeds is history only
- [feed-url-matching](docs/claude/feed-url-matching.md): `clean_and_best_matching` matches unrelated feeds; moderation uses `clean_and_direct_matching`
- [podcast-update-backoff](docs/claude/podcast-update-backoff.md): `update_intervall` does reset to 10 h on a new episode
- [podcast-person-tag](docs/claude/podcast-person-tag.md): podcast:person parsing; no backfill of old episodes, by decision
- [podcast-title-clash](docs/claude/podcast-title-clash.md): title clash, succession check, duplicates page, merge (closed)
- [failure-count-followups](docs/claude/failure-count-followups.md): retire at `>= 10`, stats candidates at `>= 9`; no workaround for user-agent blocks
- [persona-nil-name-crash](docs/claude/persona-nil-name-crash.md): nameless personas fixed and backfilled
- [unknown-language-codes](docs/claude/unknown-language-codes.md): unknown language codes stay as UUID-named rows; name them by hand
- [feed-compliance-checker](docs/claude/feed-compliance-checker.md): Project #2, check_my_feed library: release steps, left-out ideas; 0.6.0 (German) release pending

**HTTP and dependencies**
- [hackney-http2-disabled](docs/claude/hackney-http2-disabled.md): HTTP/1.1 only, because hackney 4's HTTP/2 stalls
- [httpoison-req-migration](docs/claude/httpoison-req-migration.md): hackney CVEs fixed via HTTPoison 3; Req migration not needed
- [insecure-tls-http-fetches](docs/claude/insecure-tls-http-fetches.md): two intentional sites that skip certificate checks
- [dialyzer-httpoison-false-positives](docs/claude/dialyzer-httpoison-false-positives.md): six Dialyzer warnings in feed_probe.ex, leave them
- [mix-overrides](docs/claude/mix-overrides.md): gettext/inflex/npm overrides: why, and when each can go
- [otp28-deps](docs/claude/otp28-deps.md), [otp29-upgrade](docs/claude/otp29-upgrade.md): toolchain upgrades; keep exactly one previous version installed
- [dead-module-sweep](docs/claude/dead-module-sweep.md): xref recipe for unused modules, expected false positives

**Search (Manticore)**
- [manticore-search](docs/claude/manticore-search.md): HTTP API endpoint/content-type map, `Manticore.sql/1`
- [manticore-podcast-sync](docs/claude/manticore-podcast-sync.md): full_text push model, who re-flags what, prod runbook
- [manticore-delete-sync](docs/claude/manticore-delete-sync.md): index cleanup on delete; accepted gap: no cascade to children
- [category-merge-pool-exhaustion](docs/claude/category-merge-pool-exhaustion.md): ReflagQueue; never call `get_connection_metrics` on Pan.Repo

**Features and projects**
- [community-pads](docs/claude/community-pads.md): Project #3 pads: decisions, code map, gotchas; community slugs in URLs
- [multilingual](docs/claude/multilingual.md): Project #4 EN/DE: decisions, code map, gettext gotchas
- [curator-feature](docs/claude/curator-feature.md): curator role and curations, decisions Q1–48
- [podcast-ownership-phase-b](docs/claude/podcast-ownership-phase-b.md): podcast claiming design (podcasts.user_id, auto-assign by owner email)
- [access-phase-order-sept21](docs/claude/access-phase-order-sept21.md): access phase A skipped; verification overhaul complete
- [api-error-page](docs/claude/api-error-page.md): API error page for community moderators, former_podcasts
- [category-apple-cleanup](docs/claude/category-apple-cleanup.md): categories cleaned up to Apple's list; mapping table; stray-check routine
- [retention-notice-job](docs/claude/retention-notice-job.md): SendRetentionNotices job, prod only, stays running
- [pro-plan-retirement](docs/claude/pro-plan-retirement.md): pro plan retired; Invoice model kept on purpose
- [catppuccin-themes](docs/claude/catppuccin-themes.md), [daisy-ui-migration](docs/claude/daisy-ui-migration.md): themes and UI class conventions
- [business-cards](docs/claude/business-cards.md): Panoptikum business card in `../pan-assets/business-cards/`

<!-- usage-rules-start -->
<!-- usage-rules-header -->
# Usage Rules

**IMPORTANT**: Consult these usage rules early and often when working with the packages listed below.
Before attempting to use any of these packages or to discover if you should use them, review their
usage rules to understand the correct patterns, conventions, and best practices.
<!-- usage-rules-header-end -->

<!-- mdex-start -->
## mdex usage
_Fast and extensible Markdown for Elixir_

[mdex usage rules](deps/mdex/usage-rules.md)
<!-- mdex-end -->
<!-- igniter-start -->
## igniter usage
_A code generation and project patching framework_

[igniter usage rules](deps/igniter/usage-rules.md)
<!-- igniter-end -->
<!-- claude-start -->
## claude usage
_Batteries-included Claude Code integration for Elixir projects_

[claude usage rules](deps/claude/usage-rules.md)
<!-- claude-end -->
<!-- claude:subagents-start -->
## claude:subagents usage
[claude:subagents usage rules](deps/claude/usage-rules/subagents.md)
<!-- claude:subagents-end -->
<!-- usage_rules-start -->
## usage_rules usage
_A dev tool for Elixir projects to gather LLM usage rules from dependencies_

[usage_rules usage rules](deps/usage_rules/usage-rules.md)
<!-- usage_rules-end -->
<!-- usage_rules:elixir-start -->
## usage_rules:elixir usage
[usage_rules:elixir usage rules](deps/usage_rules/usage-rules/elixir.md)
<!-- usage_rules:elixir-end -->
<!-- usage_rules:otp-start -->
## usage_rules:otp usage
[usage_rules:otp usage rules](deps/usage_rules/usage-rules/otp.md)
<!-- usage_rules:otp-end -->
<!-- phoenix:ecto-start -->
## phoenix:ecto usage
[phoenix:ecto usage rules](deps/phoenix/usage-rules/ecto.md)
<!-- phoenix:ecto-end -->
<!-- phoenix:elixir-start -->
## phoenix:elixir usage
[phoenix:elixir usage rules](deps/phoenix/usage-rules/elixir.md)
<!-- phoenix:elixir-end -->
<!-- phoenix:html-start -->
## phoenix:html usage
[phoenix:html usage rules](deps/phoenix/usage-rules/html.md)
<!-- phoenix:html-end -->
<!-- phoenix:liveview-start -->
## phoenix:liveview usage
[phoenix:liveview usage rules](deps/phoenix/usage-rules/liveview.md)
<!-- phoenix:liveview-end -->
<!-- phoenix:phoenix-start -->
## phoenix:phoenix usage
[phoenix:phoenix usage rules](deps/phoenix/usage-rules/phoenix.md)
<!-- phoenix:phoenix-end -->
<!-- usage-rules-end -->
