defmodule Pan.SearchFrontendController do
  use Pan.Web, :controller
  import Tirexs.Search
  require Logger

  def new(conn, params) do
    size = 10
    from = unless params["page"] in ["", nil] do
             (String.to_integer(params["page"]) - 1) * size
           else
             0
           end

    page = round((from + 10) / size)

    query = search [index: "/panoptikum_" <> Application.get_env(:pan, :environment)] do
      query do
        match "_all", params["search"]["searchstring"]
      end
      size size
      from from
    end

    case Tirexs.Query.create_resource(query) do
      {:ok, 200, %{hits: hits, took: took}} ->
        total = Enum.min([hits.total, 10000])
        render(conn, "new.html", searchstring: params["search"]["searchstring"],
                                 hits: hits, took: took, from: from, size: size, page: page,
                                 total: total)
      {:error, 500, %{error: %{caused_by: %{reason: reason}}}} ->
        render(conn, "error.html")
        raise reason
    end
  end
end