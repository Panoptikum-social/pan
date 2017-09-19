defmodule PanWeb.Api.SessionView do
  use Pan.Web, :view
  use JaSerializer.PhoenixView # Or use in web/web.ex

  attributes [:token, :created_at, :valid_for, :valid_until]
end