defmodule PanWeb.SearchFrontendController do
  use Pan.Web, :controller
  require Logger

  def new(conn, %{"page" => page, "search" => %{"searchstring" => search_term} }) do
    limit = 10
    index= "episodes"

    offset = if page in ["", nil], do: 0, else: (String.to_integer(page) - 1) * limit
    _page = round((offset + 10) / limit)

    Pan.Search.query(index: index, search_term: search_term, limit: limit, offset: offset)
    render(conn, "done.html")
  end

  def new(conn, %{"search" => %{"searchstring" => search_term} }) do
    limit = 10
    index = "episodes"

    hits = Pan.Search.query(index: index, search_term: search_term, limit: limit, offset: 0)
    render(conn, "#{index}.html", hits: hits)
  end
end
