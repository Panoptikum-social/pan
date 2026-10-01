defmodule PanWeb.SearchController do
  use PanWeb, :controller
  alias Pan.Search
  alias PanWeb.PageFrontendView
  require Logger

  def migrate(conn, _params) do
    Task.start(fn -> Pan.Search.migrate() end)

    conn
    |> put_view(PageFrontendView)
    |> render("started.html", %{})
  end

  def push_missing(conn, _params) do
    Task.start(fn -> Search.push_missing() end)

    conn
    |> put_view(PageFrontendView)
    |> render("started.html", %{})
  end

  def reset_all(conn, _params) do
    Task.start(fn -> Search.reset_all() end)

    conn
    |> put_view(PageFrontendView)
    |> render("started.html", %{})
  end

  def delete_orphans(conn, _params) do
    # the episodes alone take about a minute — too long for a request
    Task.start(fn ->
      Logger.info("Full text search orphans deletion started")
      Search.Category.delete_index_orphans()
      Logger.info("Category orphans deleted")

      Search.Podcast.delete_index_orphans()
      Logger.info("Podcast orphans deleted")

      Search.Episode.delete_index_orphans()
      Logger.info("Episode orphans deleted")

      Search.Persona.delete_index_orphans()
      Logger.info("Persona orphans deleted")

      Logger.info("Full text search orphans deletion finished")
    end)

    conn
    |> put_view(PageFrontendView)
    |> render("started.html", %{})
  end
end
