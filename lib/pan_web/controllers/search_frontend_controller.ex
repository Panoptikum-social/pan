defmodule PanWeb.SearchFrontendController do
  use Pan.Web, :controller
  require Logger

  def new(conn, params) do
    size = 10
    from = unless params["page"] in ["", nil] do
             (String.to_integer(params["page"]) - 1) * size
           else
             0
           end

    page = round((from + 10) / size)

    query = [index: "/panoptikum_" <> Application.get_env(:pan, :environment),
             search: [size: size, from: from,
               query: [
                 function_score: [
                   query: [match: [_all: [query: params["search"]["searchstring"]]]],
                   boost_mode: "multiply",
                   functions: [
                     %{filter: [term: ["_type": "categories"]], weight: 5},
                     %{filter: [term: ["_type": "podcasts"]], weight: 4},
                     %{filter: [term: ["_type": "personas"]], weight: 3},
                     %{filter: [term: ["_type": "episodes"]], weight: 2},
                     %{filter: [term: ["_type": "users"]], weight: 1}]]]]]

    case Tirexs.Query.create_resource(query) do
      {:ok, 200, %{hits: hits, took: took}} ->
        total = Enum.min([hits.total, 10000])
        render(conn, "new.html", searchstring: params["search"]["searchstring"],
                                 hits: hits, took: took, from: from, size: size, page: page,
                                 total: total)
      {:error, number, %{error: %{caused_by: %{reason: reason}}}} ->
        render(conn, "error.html")
        raise reason
    end
  end
end