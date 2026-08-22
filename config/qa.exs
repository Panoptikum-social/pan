import Config

# Database and Mailer credentials live in qa.secret.exs (gitignored),
# same convention as prod.secret.exs — see config/qa.secret.exs.example.

config :pan, PanWeb.Endpoint,
  http: [ip: {0, 0, 0, 0}, port: 4000],
  url: [scheme: "http", host: "qa.panoptikum.social", port: 4001],
  cache_static_manifest: "priv/static/cache_manifest.json",
  server: true,
  root: ".",
  check_origin: ["http://qa.panoptikum.social:4001"],
  version: Mix.Project.config()[:version]

config :logger, level: :info

config :phoenix, :serve_endpoints, true

config :pan, :environment, "qa"

# Manticore runs as its own container in the QA docker-compose stack,
# not on localhost like the bare-metal dev/prod setup.
config :pan, :manticore_url, "http://search:9308"

config :pan, :children, [
  Pan.Repo,
  PanWeb.Telemetry,
  {Phoenix.PubSub, name: :pan_pubsub, adapter: Phoenix.PubSub.PG2},
  PanWeb.Endpoint,
  Pan.Job.ImportStalePodcasts,
  Pan.Job.CacheMissingImages,
  Pan.Job.PushMissingSearchIndex
]

import_config "qa.secret.exs"
