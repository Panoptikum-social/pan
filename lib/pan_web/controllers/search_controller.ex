defmodule PanWeb.SearchController do
  use Pan.Web, :controller
  alias Pan.Search
  require Logger

  def full_text_search_push_missing(conn, _params) do
    Search.push_missing()
    render(conn, "done.html", %{})
  end

  def full_text_search_reset_all(conn, _params) do
    Search.reset_all()
    render(conn, "done.html", %{})
  end

  def full_text_search_delete_orphans(conn, _params) do
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
