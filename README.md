# Panoptikum

Panoptikum (or short Pan) is a webapplication written in [Phoenix](http://www.phoenixframework.org/)
that represents a podcast discovery and community website.

It is licensed under the AGPL license.
The project website with more information on the project can be found at <https://www.panoptikum.social>
If you are interested and want to get in touch, write an email to [Stefan](mailto:stefan@panoptikum.social).

## Setup

### 📋 Prerequirements

* Make sure you have [Elixir](https://elixir-lang.org) installed.
* Make sure you have [Node.js](https://nodejs.org) installed.
* Make sure you have [PostgreSQL](https://www.postgresql.org) installed and running.
* Make sure you have [ManticoreSearch](https://manticoresearch.com/) installed and running.

### 📦 Install dependencies

* Install Elixir's dependencies with `mix deps.get`
* Install Node.js dependencies with `npm install` _inside the assets folder_

### 🛠 Configuration

* Dev works out of the box with no configuration — `config/runtime.exs` falls
  back to sensible local defaults (Postgres `postgres`/`postgres`, database
  `pan_dev`) if you don't set any env vars. Only set `PAN_DB_USERNAME` /
  `PAN_DB_PASSWORD` / `PAN_DB_DATABASE` / `PAN_DB_HOSTNAME` if your local
  Postgres needs different credentials.

### 📚 Database and demo data

* Setup your database with `mix ecto.setup`
* Import demo data
  * Uncompress `materials/pan_dev.sql.gz`
  * Import data with `psql pan_dev < pan_dev.sql` _inside the materials folder_
  * The dump already includes an admin user, username `admin` and password
    `changeme` — no seeding step needed (`priv/repo/seeds.exs` is currently
    just an empty template)

### ⏯ Run locally

* Start Phoenix endpoint with `mix phx.server`
* Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.
* Login as Admin using username `admin` and password `changeme`

### 🌡 Testing

* Run tests with `mix test`

## 🐳 QA environment

To stand up a disposable QA deployment on a separate server via Docker
Compose, see [DOCKER.md](DOCKER.md).

### ✨ Bonus

* Sending a Test Mail from the console
  `Pan.Email.login_link_html_email("mytoken", "my-email@example.com") |> Pan.Mailer.deliver()`
* To rebuild the search index login as `admin` and visit [`localhost:4000/admin/search/reset_all`](http://localhost:4000/admin/search/reset_all)
* To attach to a server session:
  `/var/phoenix/pan/bin/pan remote` and then, for example `PanWeb.Podcast.get_deprecated(10)` to probe deprecated podcasts and get delete/unretire recommendations

## 🙏 Sitting on the shoulders of giants

Panoptikum is only possible because of an enormous amount of open-source work
by others. Thank you.

### Server stack

* [Elixir](https://elixir-lang.org) & [Erlang/OTP](https://www.erlang.org)
* [Phoenix](https://www.phoenixframework.org) — web framework
* [Ecto](https://hexdocs.pm/ecto) & [Postgrex](https://hexdocs.pm/postgrex) — database layer
* [PostgreSQL](https://www.postgresql.org) — database
* [Phoenix LiveView](https://hexdocs.pm/phoenix_live_view)
* [Bandit](https://hexdocs.pm/bandit) — web server
* [Manticore Search](https://manticoresearch.com) — full text search
* [Quinn](https://hexdocs.pm/quinn) — XML parsing for feed import
* [HTTPoison](https://hexdocs.pm/httpoison) — HTTP client
* [Timex](https://hexdocs.pm/timex) & [tzdata](https://hexdocs.pm/tzdata) — date and time handling
* [HtmlSanitizeEx](https://hexdocs.pm/html_sanitize_ex) — sanitizing feed HTML
* [Floki](https://hexdocs.pm/floki) — HTML parsing
* [MDEx](https://hexdocs.pm/mdex) — Markdown rendering
* [Swoosh](https://hexdocs.pm/swoosh) & [gen_smtp](https://hexdocs.pm/gen_smtp) — mailing
* [bcrypt_elixir](https://hexdocs.pm/bcrypt_elixir) — password hashing
* [ja_serializer](https://hexdocs.pm/ja_serializer) — JSON:API serialization
* [Mogrify](https://hexdocs.pm/mogrify) & [ImageMagick](https://imagemagick.org) — image processing
* [eqrcode](https://hexdocs.pm/eqrcode) — QR code generation
* [Gettext](https://hexdocs.pm/gettext) — i18n
* [Telemetry](https://hexdocs.pm/telemetry_metrics) & [ecto_psql_extras](https://hexdocs.pm/ecto_psql_extras) — observability
* [Tailwind CSS](https://tailwindcss.com) & [DaisyUI](https://daisyui.com) — styling
* [Alpine.js](https://alpinejs.dev) — frontend interactivity
* [topbar](https://github.com/buunguyen/topbar) — page-load progress bar
* [Podlove Web Player](https://github.com/podlove/ui/tree/development/apps/web-player) — podcast episode player

### Development stack

* [Linux Mint](https://linuxmint.com) — development OS
* [Visual Studio Code](https://code.visualstudio.com) — editor
* [Docker](https://www.docker.com) & [Docker Compose](https://docs.docker.com/compose/) — QA environment, see [DOCKER.md](DOCKER.md)
* [Node.js](https://nodejs.org) & [npm](https://www.npmjs.com) — frontend asset tooling
* [esbuild](https://esbuild.github.io) — JS bundling
* [Credo](https://hexdocs.pm/credo) — static code analysis
* [Igniter](https://hexdocs.pm/igniter) — codegen/patching framework
* [Claude Code](https://claude.com/claude-code) & [Tidewave](https://tidewave.ai) — AI-assisted development
* [usage_rules](https://hexdocs.pm/usage_rules) — gathering dependency usage guidance for AI coding tools