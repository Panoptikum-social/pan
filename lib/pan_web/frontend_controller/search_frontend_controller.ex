defmodule PanWeb.SearchFrontendController do
  use PanWeb, :controller
  require Logger

  def search(conn, %{"index" => index, "page" => page, "term" => term}) do
    page = String.to_integer(page) || 1
    limit = 10
    offset = (page - 1) * limit
    hits = Pan.Search.query(index: index, term: term, limit: limit, offset: offset)

    render(conn, "#{index}.html",
      hits: hits, page: page, offset: offset, term: term, hits_count: hits["hits"] |> length,
      total: hits["total"], size: limit )
  end

  def search(conn, %{"index" => index, "term" => term}) do
    search(conn, %{"page" => "1", "index" => index, "term" => term})
  end

  def new(conn, %{"search" => %{"term" => term}}) do
    search(conn, %{"page" => "1", "index" => "episodes", "term" => term})
  end
end
