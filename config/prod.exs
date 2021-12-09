import Config

config :pan, PanWeb.Endpoint,
  # url: [host: "example.com", port: 80],
  url: [host: "localhost", port: 4000],
  cache_static_manifest: "priv/static/cache_manifest.json"

# Do not print debug messages in production
config :logger, level: :info

import_config "prod.secret.exs"
