defmodule PanWeb.SearchFrontendController do
  use Pan.Web, :controller
  require Logger

  def new(conn, %{"page" => page, "search" => %{"term" => term}}) do
    limit = 10
    index = "episodes"

    offset = if page in ["", nil], do: 0, else: (String.to_integer(page) - 1) * limit
    page = round((offset + 10) / limit)

    hits = Pan.Search.query(index: index, term: term, limit: limit, offset: offset)

    render(
      conn,
      "#{index}.html",
      hits: hits,
      page: page,
      offset: offset,
      term: term,
      hits_count: hits["hits"] |> length,
      total: hits["total"],
      size: limit
    )
  end

  def new(conn, %{"search" => %{"term" => term}}) do
    new(conn, %{"page" => "1", "search" => %{"term" => term}})
  end
end
