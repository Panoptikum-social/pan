import Config

# Runtime (rather than compile-time) configuration. Evaluated after
# config/config.exs + config/#{config_env()}.exs — for `mix` tasks (dev/test)
# just like for a compiled release (qa/prod). See backlog.md, "Move qa/prod
# secrets to config/runtime.exs", for why this file exists: today the full
# config chain is compile-time only, so secrets (DB password, PanWeb.Endpoint
# secret_key_base, mailer creds) end up baked in plaintext inside the
# release/image itself — or, for dev, inside a file symlinked from a private
# sibling repo that every dev machine has to have cloned.
#
# Rollout, one environment at a time (see backlog.md for status):
#   [x] dev
#   [x] qa
#   [ ] prod — not yet migrated, still config/prod.secret.exs (symlinked from
#              pan-config on the prod host)

if config_env() == :dev do
  config :pan, Pan.Repo,
    username: System.get_env("PAN_DB_USERNAME", "postgres"),
    password: System.get_env("PAN_DB_PASSWORD", "postgres"),
    database: System.get_env("PAN_DB_DATABASE", "pan_dev"),
    hostname: System.get_env("PAN_DB_HOSTNAME", "localhost"),
    show_sensitive_data_on_connection_error: true,
    pool_size: 10

  # Legacy Facebook Messenger bot integration (see lib/pan/bot.ex) — nil when
  # unset is fine, it's only read by the handful of functions in that module,
  # never at boot.
  config :pan, :bot,
    fb_access_token: System.get_env("PAN_BOT_FB_ACCESS_TOKEN"),
    host: System.get_env("PAN_BOT_HOST")

  # Dev never actually sends real mail — this used to be real SMTP creds in
  # dev.secret.exs, but dev.exs unconditionally overrode the adapter to
  # Local afterwards, so those creds (the same password as prod's mailer)
  # were dead config. Made explicit here instead of silently dead.
  config :pan, Pan.Mailer, adapter: Swoosh.Adapters.Local
end

if config_env() == :qa do
  # A real deploy, unlike dev — missing required values raise instead of
  # silently falling back. All of these come from docker-compose.yml's
  # `environment:` block for the `app` service, itself sourced from a
  # gitignored `.env` file (see .env.example) so the same value can be
  # shared with the `db` service without duplicating it in two places.
  database_password =
    System.get_env("POSTGRES_PASSWORD") ||
      raise "environment variable POSTGRES_PASSWORD is missing"

  config :pan, Pan.Repo,
    username: System.get_env("POSTGRES_USER", "postgres"),
    password: database_password,
    database: System.get_env("POSTGRES_DB", "pan_qa"),
    # "db" is the Postgres service name in docker-compose.yml
    hostname: System.get_env("POSTGRES_HOST", "db"),
    pool_size: 10

  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise "environment variable SECRET_KEY_BASE is missing"

  host = System.get_env("PAN_HOST") || raise "environment variable PAN_HOST is missing"
  port = String.to_integer(System.get_env("PAN_PORT", "4001"))

  config :pan, PanWeb.Endpoint,
    secret_key_base: secret_key_base,
    url: [scheme: "http", host: host, port: port],
    check_origin: ["http://#{host}:#{port}"]

  # Defaults to not sending real mail from QA. Switch to Swoosh.Adapters.SMTP
  # (see the prod branch below, once migrated) if you need to test outgoing
  # mail flows from this environment.
  config :pan, Pan.Mailer, adapter: Swoosh.Adapters.Local
end
