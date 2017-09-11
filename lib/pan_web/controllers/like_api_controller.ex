defmodule PanWeb.LikeApiController do
  use Pan.Web, :controller

  def create(conn, params) do
    IO.inspect params

    render conn, "show.json-api", data: nil
  end
end
