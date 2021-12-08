defmodule PanWeb.SearchFrontendController do
  use PanWeb, :controller
  require Logger

  def new(conn, %{"search" => %{"term" => term}}) do
    redirect(conn, to: search_frontend_path(conn, :search, "episodes", term))
  end
end
