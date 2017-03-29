defmodule Pan.SearchFrontendController do
  use Pan.Web, :controller
  import Tirexs.Search

  def new(conn, params) do
    size = 10
    from = unless params["page"] in ["", nil] do
             String.to_integer(params["page"]) * size
           else
             0
           end

    page = round((from - 1) / size)

    query = search [index: "/panoptikum_" <> Atom.to_string(Mix.env)] do
      query do
        match "_all", params["search"]["searchstring"]
      end
      size size
      from from
    end

    {:ok, 200, %{hits: hits, took: took}} = Tirexs.Query.create_resource(query)

    render(conn, "new.html", searchstring: params["search"]["searchstring"],
                             hits: hits, took: took, from: from, size: size, page: page)
  end
end