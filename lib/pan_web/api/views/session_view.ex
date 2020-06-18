defmodule PanWeb.Api.SessionView do
  use Pan.Web, :view
  # Or use in web/web.ex
  use JaSerializer.PhoenixView

  attributes([:token, :created_at, :valid_for, :valid_until])
end
