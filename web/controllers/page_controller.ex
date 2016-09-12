defmodule Pan.PageController do
  use Pan.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
