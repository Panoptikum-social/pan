defmodule Pan.Repo do
  use Ecto.Repo, otp_app: :pan
  use Scrivener, page_size: 15
end
