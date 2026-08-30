# 🐳 QA environment (Docker)

## 📋 Prerequisites

* QA server running Ubuntu 24.04 (`Dockerfile` base images are pinned to
  match; see Troubleshooting if the server OS differs)
* Docker + Docker Compose v2 on the QA server
* This repo checked out on that server
* Your user is in the `docker` group (`sudo usermod -aG docker $USER`,
  then log out/in) — otherwise prefix every command below with `sudo`

## 📊 Resource usage

Rough numbers from a real QA instance shortly after startup, running the
demo dataset (`materials/pan_dev.sql.gz`):

* **RAM**: ~800 MiB total (`docker stats --no-stream`) — app ~300 MiB, db
  (Postgres) ~210 MiB, search (Manticore) ~290 MiB.
* **Disk — images**: ~2 GB total (`docker system df -v`) — app ~406 MB,
  Manticore ~928 MB, Postgres ~645 MB. One-time cost after `docker compose
  build`/`pull`.
* **Disk — data volumes**: ~540 MB with the demo dataset — `db_data` ~453
  MB, `search_data` ~88 MB, `uploads` empty. Grows with real usage
  (episodes, uploaded OPML files, search index size).

Budget for at least 1–2 GB RAM and a few GB of disk free; both will grow
somewhat as the QA dataset accumulates more content over time.

## 🔥 Firewall

Docker publishes container ports by inserting its own `iptables`/`nftables`
rules, bypassing `ufw`'s normal `INPUT` chain — a plain `ufw allow 4001`
has no effect on traffic Docker forwards to a container. Use `ufw route
allow` instead, scoped to whatever network should reach the QA app:

```sh
sudo ufw route allow proto tcp from 10.0.0.0/16 to any port 4001 comment 'panoptikum-qa'
```

Adjust the source CIDR and port (if you changed the published port away
from `4001`) to match your setup.

## 🛠 Setup

```sh
cp .env.example .env
$EDITOR .env
```

In `.env`, set:

* `POSTGRES_PASSWORD` — shared by both the `db` and `app` services (see
  `docker-compose.yml`), so it only needs setting once.
* `SECRET_KEY_BASE`:
  ```sh
  openssl rand -base64 48
  ```
* `PAN_HOST` — change to this server's actual domain/IP.
* `PAN_PORT` — only needed if you change the published port away from
  `4001` (see below).

All of this lives only in `.env` (gitignored), so a later `git pull` on
this server never conflicts with these settings. `docker compose` loads
`.env` automatically — no extra flag needed. Nothing here is baked into the
image; it's read by the app at container start (`config/runtime.exs`), so
changing `.env` only needs `docker compose up -d` (not a rebuild) to take
effect — see Update below.

## 🏗 Build and run

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

The dump already includes an admin user: username `admin`, password
`changeme`.

App is published on host port `4001` by default (edit `ports:` in
`docker-compose.yml` to change).

## 🔍 Verify

```sh
docker compose ps
docker compose logs -f app
```

Visit `http://<qa-server>:4001`.

## 🖥 Remote console

```sh
docker compose exec app bin/pan remote
```

## 🔄 Update after a code change

```sh
git pull
docker compose build
docker compose up -d
```

## 🧹 Reset to a clean slate

Wipes database and search index:

```sh
docker compose down -v
docker compose up -d
```

## 🔧 Troubleshooting

* `docker compose` refuses to run at all, complaining a variable "is not
  set" — `.env` is missing or incomplete; see Setup above.
* `docker compose build` fails to pull the base image — check
  [hub.docker.com/r/hexpm/elixir/tags](https://hub.docker.com/r/hexpm/elixir/tags)
  for a current tag, adjust `UBUNTU_TAG` at the top of `Dockerfile`. If the
  server OS isn't Ubuntu 24.04, also update `RUNNER_IMAGE` to match.
* OPML uploads live in the `uploads` named volume
  (`/var/phoenix/pan-uploads`) — persists across `up`/`down`, cleared only
  by `down -v`.
* Manticore URL is set via `config :pan, :manticore_url` in `config/qa.exs`.
