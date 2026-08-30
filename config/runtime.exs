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
#   [ ] qa   — not yet migrated, still config/qa.secret.exs
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
