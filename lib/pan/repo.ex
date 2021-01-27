defmodule Pan.Repo do
  use Ecto.Repo,
    otp_app: :pan,
    adapter: Ecto.Adapters.Postgres
end
