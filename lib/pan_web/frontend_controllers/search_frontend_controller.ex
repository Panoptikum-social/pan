defmodule PanWeb.SearchFrontendController do
  use Pan.Web, :controller
  require Logger

  def new(conn, params) do
    size = 10
    from = if params["page"] in ["", nil] do
      0
    else
      (String.to_integer(params["page"]) - 1) * size
    end

    page = round((from + 10) / size)

    query = [index: "/panoptikum_" <> Application.get_env(:pan, :environment),
             search: [size: size, from: from,
               query: [
                 function_score: [
                   query: [match: [_all: [query: params["search"]["searchstring"]]]],
                   boost_mode: "multiply",
                   functions: [
                     %{filter: [term: [_type: "categories"]], weight: 20},
                     %{filter: [term: [_type: "podcasts"]], weight: 10},
                     %{filter: [term: [_type: "personas"]], weight: 3},
                     %{filter: [term: [_type: "episodes"]], weight: 2},
                     %{filter: [term: [_type: "users"]], weight: 1}]]]]]

    case Tirexs.Query.create_resource(query) do
      {:ok, 200, %{hits: hits, took: took}} ->
        total = Enum.min([hits.total, 10_000])
        render(conn, "new.html", searchstring: params["search"]["searchstring"],
                                 hits: hits, took: took, from: from, size: size, page: page,
                                 total: total)
      {:error, _number, %{error: %{caused_by: %{reason: reason}}}} ->
        render(conn, "error.html")
        raise reason
    end
  end
end
