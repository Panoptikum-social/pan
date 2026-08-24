import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :pan, Pan.Repo,
  username: "postgres",
  password: "postgres",
  database: "pan_test#{System.get_env("MIX_TEST_PARTITION")}",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

# We don't run a server during test.
config :pan, PanWeb.Endpoint,
  http: [port: 4002],
  server: false

# Only the infrastructure controller/LiveView tests need to start the app -
# no background jobs (feed imports, image caching, search indexing), so
# tests stay fast and don't depend on external services like Manticore.
config :pan, :children, [
  Pan.Repo,
  PanWeb.Telemetry,
  {Phoenix.PubSub, name: :pan_pubsub, adapter: Phoenix.PubSub.PG2},
  PanWeb.Endpoint
]

# Print only warnings and errors during test
config :logger, level: :warn
