# QA environment (Docker)

This sets up a self-contained QA deployment on its own Linux server, using
Docker Compose. It's a separate path from the existing bare-metal prod
deploy described in the main [README](README.md) — prod isn't touched by
any of this, and the two can evolve independently.

The stack is three containers:

* **app** — the Phoenix release (built from this repo's `Dockerfile`)
* **db** — PostgreSQL
* **search** — ManticoreSearch

## 📋 Prerequisites

* Docker and Docker Compose v2 installed on the QA server.
* This repo checked out on that server (the image is built there, not
  shipped in from elsewhere — see [Secrets](#-secrets) below for why).

## 🛠 Secrets

Database credentials, `secret_key_base`, and mailer settings live in
`config/qa.secret.exs`, which is gitignored — same convention as
`config/prod.secret.exs` today. It gets **compiled into the release at
build time**, which is why the image has to be built on the QA server
itself rather than elsewhere (e.g. CI) and shipped in.

```sh
cp config/qa.secret.exs.example config/qa.secret.exs
$EDITOR config/qa.secret.exs
```

At minimum, set:

* `Pan.Repo` password — must match `POSTGRES_PASSWORD` in `docker-compose.yml`
  (defaults to `changeme` in both places; change both together).
* `PanWeb.Endpoint` `secret_key_base` — generate one with `mix phx.gen.secret`.

## 🌐 Hostname

`config/qa.exs` has a placeholder host, `qa.panoptikum.social`, used for
the endpoint URL and `check_origin`. Change it to whatever domain or IP
this QA server will actually be reached at before building.

## 📦 Build and run

```sh
docker compose build
docker compose up -d
```

On startup, the `app` container runs pending Ecto migrations
(`Pan.Release.migrate/0`, see `lib/pan/release.ex`) before starting the
server — no separate migration step needed.

By default the app is published on host port `4001` (container port
`4000`); change the `ports:` mapping in `docker-compose.yml` if that
collides with something else on the server.

## 🔍 Verifying it's up

```sh
docker compose ps
docker compose logs -f app
```

Visit `http://<qa-server>:4001` (or whatever port/hostname you configured).

## 🧑‍💻 Attaching a remote console

Same idea as the bare-metal `/var/phoenix/pan/bin/pan remote` from the
main README, just run inside the container:

```sh
docker compose exec app bin/pan remote
```

## 🔄 Updating after a code change

```sh
git pull
docker compose build
docker compose up -d
```

## 🧹 Resetting QA to a clean slate

This throws away the database and search index (the whole point of a
disposable QA box):

```sh
docker compose down -v
docker compose up -d
```

## Notes / things to double check

* The Dockerfile pins a `hexpm/elixir` base image tag matched to this
  repo's `.tool-versions` (Elixir/OTP versions) at the time it was
  written. hexpm only keeps recent Debian snapshot dates published —
  if `docker compose build` fails to pull the base image, check
  [hub.docker.com/r/hexpm/elixir/tags](https://hub.docker.com/r/hexpm/elixir/tags)
  for a valid tag and adjust the `DEBIAN_VERSION` build arg at the top
  of the `Dockerfile`.
* OPML uploads are written to a fixed path (`/var/phoenix/pan-uploads`)
  that's mounted as a named Docker volume — it persists across
  `docker compose up`/`down` (without `-v`), same as the `db`/`search`
  volumes.
* ManticoreSearch's URL is configurable via `config :pan, :manticore_url`
  (see `config/qa.exs`) — it defaults to `http://localhost:9308`
  everywhere else (dev/prod), so this only affects QA.
