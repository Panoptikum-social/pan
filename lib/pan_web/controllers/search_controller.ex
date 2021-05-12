defmodule PanWeb.SearchController do
  use Pan.Web, :controller
  alias Pan.Search
  require Logger

  def elasticsearch_push_missing(conn, _params) do
    Search.push_missing()
    render(conn, "done.html", %{})
  end

  def elasticsearch_push_all(conn, _params) do
    Search.push_all()
    render(conn, "done.html", %{})
  end

  def elasticsearch_delete_orphans(conn, _params) do
    Logger.info("=== Elasticsearch orphans deletion started ===")
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

    Logger.info("=== Elasticsearch orphans deletion finished ===")
    render(conn, "done.html", %{})
  end
end
