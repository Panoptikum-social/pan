import Config

# Database, PanWeb.Endpoint url/check_origin/secret_key_base, and Mailer
# credentials are all env-var driven now — see config/runtime.exs's
# `config_env() == :qa` branch and .env.example.

config :pan, PanWeb.Endpoint,
  http: [ip: {0, 0, 0, 0}, port: 4000],
  cache_static_manifest: "priv/static/cache_manifest.json",
  server: true,
  root: ".",
  version: Mix.Project.config()[:version]

config :logger, level: :info

config :phoenix, :serve_endpoints, true

config :pan, :environment, "qa"

# Manticore runs as its own container in the QA docker-compose stack,
# not on localhost like the bare-metal dev/prod setup.
config :pan, :manticore_url, "http://search:9308"

# pid_file is a hard OTP application dependency of :pan (it's a normal Mix
# dep) — if it fails to start, :pan never starts either, regardless of its
# release start_type. The container's working directory isn't writable by
# the app user, so point it at /tmp instead of the default "./pan.pid".
# Nothing reads this file in QA (unlike bare-metal prod, where monit does).
config :pid_file, file: "/tmp/pan.pid"

config :pan, :children, [
  Pan.Repo,
  PanWeb.Telemetry,
  {Phoenix.PubSub, name: :pan_pubsub, adapter: Phoenix.PubSub.PG2},
  PanWeb.Endpoint,
  Pan.Job.ImportStalePodcasts,
  Pan.Job.CacheMissingImages,
  Pan.Job.PushMissingSearchIndex
]
