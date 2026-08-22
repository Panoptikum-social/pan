# QA environment (Docker)

## Prerequisites

* QA server running Ubuntu 24.04 (`Dockerfile` base images are pinned to
  match; see Troubleshooting if the server OS differs)
* Docker + Docker Compose v2 on the QA server
* This repo checked out on that server
* Your user is in the `docker` group (`sudo usermod -aG docker $USER`,
  then log out/in) — otherwise prefix every command below with `sudo`

## Setup

```sh
cp config/qa.secret.exs.example config/qa.secret.exs
$EDITOR config/qa.secret.exs
```

In `config/qa.secret.exs`, set:

* `Pan.Repo` `password` — must match `POSTGRES_PASSWORD` in `docker-compose.yml`
* `PanWeb.Endpoint` `secret_key_base`:
  ```sh
  openssl rand -base64 48
  ```
* `PanWeb.Endpoint` `url`/`check_origin` — change `qa.panoptikum.social` to
  this server's actual domain/IP. If you change the published port away
  from `4001` (see below), update the port here too.

All of this lives only in `config/qa.secret.exs` (gitignored), so a later
`git pull` on this server never conflicts with these settings.

## Build and run

```sh
docker compose build
docker compose up -d
```

On first init of an empty `db_data` volume, Postgres loads
`materials/pan_dev.sql.gz` (a baseline schema + demo data dump) before the
app container's automatic migrations run. This is required — running the
full migration history against a truly empty database fails partway
through (old migration ordering issue); the dump provides a working
baseline with `schema_migrations` already populated, so only the
migrations added since then need to apply.

App is published on host port `4001` by default (edit `ports:` in
`docker-compose.yml` to change).

## Verify

```sh
docker compose ps
docker compose logs -f app
```

Visit `http://<qa-server>:4001`.

## Remote console

```sh
docker compose exec app bin/pan remote
```

## Update after a code change

```sh
git pull
docker compose build
docker compose up -d
```

## Reset to a clean slate

Wipes database and search index:

```sh
docker compose down -v
docker compose up -d
```

## Troubleshooting

* `docker compose build` fails to pull the base image — check
  [hub.docker.com/r/hexpm/elixir/tags](https://hub.docker.com/r/hexpm/elixir/tags)
  for a current tag, adjust `UBUNTU_TAG` at the top of `Dockerfile`. If the
  server OS isn't Ubuntu 24.04, also update `RUNNER_IMAGE` to match.
* OPML uploads live in the `uploads` named volume
  (`/var/phoenix/pan-uploads`) — persists across `up`/`down`, cleared only
  by `down -v`.
* Manticore URL is set via `config :pan, :manticore_url` in `config/qa.exs`.
* `mix assets.deploy` fails with "Cannot find native binding" /
  `@tailwindcss/oxide-*` — npm optional-dependencies bug
  ([npm/cli#4828](https://github.com/npm/cli/issues/4828)), usually from an
  old apt-packaged npm. `Dockerfile` installs Node from NodeSource to avoid
  it; if it recurs, bump the Node version there.
* `app` crashes on start with a Postgres error like `relation "..." does
  not exist` during a migration — the `db_data` volume already has a
  partially-migrated, empty-origin database in it (e.g. from before the
  `materials/pan_dev.sql.gz` seed was added). Reset it: `docker compose
  down -v && docker compose up -d`. The `pan_dev.sql.gz` seed only loads
  on first init of an empty volume, not on top of an existing one.
