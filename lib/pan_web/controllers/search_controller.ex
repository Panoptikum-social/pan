defmodule PanWeb.SearchController do
  use Pan.Web, :controller
  alias Pan.Search
  require Logger

  def migrate(conn, _params) do
    # Pan.Search.Category.migrate()

    render(conn, "started.html", %{})
  end

  def push_missing(conn, _params) do
    Task.start(fn -> Search.push_missing() end)
    render(conn, "started.html", %{})
  end

  def reset_all(conn, _params) do
    Task.start(fn -> Search.reset_all() end)
    render(conn, "started.html", %{})
  end

  def delete_orphans(conn, _params) do
    Logger.info("=== Full text search orphans deletion started ===")
    PanWeb.Category.delete_search_index_orphans()
    Logger.info("=== Category orphans deleted ===")

    PanWeb.Podcast.delete_search_index_orphans()
    Logger.info("=== Podcast orphans deleted ===")

    PanWeb.Episode.delete_search_index_orphans()
    Logger.info("=== Episode orphans deleted ===")

    PanWeb.Persona.delete_search_index_orphans()
    Logger.info("=== Persona orphans deleted ===")

    PanWeb.User.delete_search_index_orphans()
    Logger.info("=== User orphans deleted ===")

    Logger.info("===  Full text search orphans deletion finished ===")
    render(conn, "done.html", %{})
  end
end
