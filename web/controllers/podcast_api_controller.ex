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
                                                         base_url: podcast_api_url(conn,:show, id)}, conn)

    podcast = Repo.get(Podcast, id)
               |> Repo.preload(episodes: from(e in Episode, order_by: [desc: e.publishing_date],
                                                            offset: ^offset,
                                                            limit: ^size))
               |> Repo.preload([:categories, :languages, :engagements, :contributors,
                               [recommendations: :user], :feeds])

    render conn, "show.json-api", data: podcast,
                                  opts: [page: links,
                                         include: "episodes,categories,languages,engagements,contributors,recommendations,feeds"]
  end


  def last_updated(conn, params) do
    page = Map.get(params, "page", %{})
           |> Map.get("number", "1")
           |> String.to_integer
    size = Map.get(params, "page", %{})
           |> Map.get("size", "10")
           |> String.to_integer
    offset = (page - 1) * size

    total = Repo.aggregate(Pan.Podcast, :count, :id)
    total_pages = div(total - 1, size) + 1

    links = JaSerializer.Builder.PaginationLinks.build(%{number: page,
                                                         size: size,
                                                         total: total_pages,
                                                         base_url: podcast_api_url(conn,:last_updated)}, conn)

    podcast_ids = from(e in Episode, order_by: [desc: max(e.publishing_date)],
                                     where: is_nil(e.publishing_date) == false and
                                            e.publishing_date < ^NaiveDateTime.utc_now(),
                                     group_by: e.podcast_id,
                                     select: e.podcast_id,
                                     limit: ^size,
                                     offset: ^offset)
                  |> Repo.all()

    podcasts = from(p in Podcast, where: p.id in ^podcast_ids)
               |> Repo.all()

    render conn, "index.json-api", data: podcasts,
                                   opts: [page: links]
  end
end
