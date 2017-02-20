use Mix.Config

config :pan, Pan.Endpoint,
  http: [port: 8888],
  url: [host: "beta.panoptikum.io", port: 443],

#  https: [port: 8888,
#          keyfile: "/etc/letsencrypt/live/beta.panoptikum.io/privkey.pem",
#          certfile: "/etc/letsencrypt/live/beta.panoptikum.io/cert.pem"],
#  url: [host: "beta.panoptikum.io", port: 443],

  cache_static_manifest: "priv/static/manifest.json",
  server: true,
  root: ".",
  version: Mix.Project.config[:version],
  force_ssl: [hsts: true],
  http: [compress: true]

config :logger, level: :info
config :phoenix, :serve_endpoints, true

import_config "prod.secret.exs"