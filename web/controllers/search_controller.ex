defmodule Pan.SearchController do
  use Pan.Web, :controller
  alias Pan.Search
  require Logger


  def elasticsearch_push(conn, %{"hours" => hours}) do
    String.to_integer(hours)
    |> Search.push()

    render(conn, "done.html", %{})
  end


  def elasticsearch_push_all(conn, _params) do
    Search.push_all()
    render(conn, "done.html", %{})
  end


  def elasticsearch_delete_orphans(conn, _params) do
    Logger.info "=== Elasticsearch orphans deletion started ==="
    Pan.Category.delete_search_index_orphans()
    Logger.info "=== Category orphans deleted ==="

    Pan.Podcast.delete_search_index_orphans()
    Logger.info "=== Podcast orphans deleted ==="

    Pan.Episode.delete_search_index_orphans()
    Logger.info "=== Episode orphans deleted ==="

    Pan.Persona.delete_search_index_orphans()
    Logger.info "=== Persona orphans deleted ==="

    Pan.User.delete_search_index_orphans()
    Logger.info "=== User orphans deleted ==="

    Logger.info "=== Elasticsearch orphans deletion finished ==="
    render(conn, "done.html", %{})
  end
end