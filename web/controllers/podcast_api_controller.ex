defmodule Pan.PodcastApiController do
  use Pan.Web, :controller
  use JaSerializer
  alias Pan.Episode
  alias Pan.Podcast


  def show(conn, %{"id" => id} = params) do
    page = Map.get(params, "page", %{})
           |> Map.get("number", "1")
           |> String.to_integer
    size = Map.get(params, "page", %{})
           |> Map.get("size", "10")
           |> String.to_integer
    offset = (page - 1) * size

    total = from(e in Pan.Episode, where: e.podcast_id == ^id)
            |> Repo.aggregate(:count, :id)
    total_pages = div(total - 1, size) + 1

    links = JaSerializer.Builder.PaginationLinks.build(%{number: page,
                                                         size: size,
                                                         total: total_pages,
                                                         base_url: "https://panoptikum.io" <> conn.request_path}, conn)

    podcast = Repo.get(Podcast, id)
               |> Repo.preload(episodes: from(e in Episode, order_by: [desc: e.publishing_date],
                                                            offset: ^offset,
                                                            limit: ^size))
               |> Repo.preload([:categories, :languages])

    render conn, "show.json-api", data: podcast, opts: [page: links, include: "episodes,categories,languages"]
  end
end
