defmodule PanWeb.PageFrontendController do
  use PanWeb, :controller

  def sandbox(conn, _params) do
    render(conn, "sandbox.html")
  end
end
