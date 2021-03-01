defmodule PanWeb.PageController do
  use PanWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
