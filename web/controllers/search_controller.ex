defmodule Pan.SearchController do
  use Pan.Web, :controller
  alias Pan.Search
  require Logger


  def elasticsearch_push(conn, %{"hours" => hours}) do
    String.to_integer(hours)
    |> Search.push()

    render(conn, "done.html", %{})
  end


  def elasticsearch_delete_orphans(conn, _params) do
    Logger.info "=== Elasticsearch orphans deletion started ==="
    Pan.Category.delete_search_index_orphans()
    Logger.info "=== Category orphans deleted ==="

    Logger.info "=== Elasticsearch orphans deletion finished ==="
    render(conn, "done.html", %{})
  end
end