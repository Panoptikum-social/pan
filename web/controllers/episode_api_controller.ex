defmodule Pan.EpisodeApiController do
  use Pan.Web, :controller
  use JaSerializer
  alias Pan.Episode

  def index(conn, params) do
    page = Map.get(params, "page", %{})
           |> Map.get("number", "1")
           |> String.to_integer
    size = Map.get(params, "page", %{})
           |> Map.get("size", "10")
           |> String.to_integer
    offset = (page - 1) * size

    total = from(e in Episode, join: p in assoc(e, :podcast),
                               where: (is_nil(p.blocked) or p.blocked == false) and
                                      e.publishing_date < ^NaiveDateTime.utc_now())
            |> Repo.aggregate(:count, :id)
    total_pages = div(total - 1, size) + 1

    links = JaSerializer.Builder.PaginationLinks.build(%{number: page,
                                                         size: size,
                                                         total: total_pages,
                                                         base_url: episode_api_url(conn,:index)}, conn)

    episodes = from(e in Episode, join: p in assoc(e, :podcast),
                                  where: (is_nil(p.blocked) or p.blocked == false) and
                                   e.publishing_date < ^NaiveDateTime.utc_now(),
                                  order_by: [desc: :publishing_date],
                                  preload: [:podcast, :gigs, :contributors],
                                  limit: ^size,
                                  offset: ^offset)
               |> Repo.all()

    render conn, "index.json-api", data: episodes,
                                   opts: [page: links,
                                          include: "podcast,gigs,contributors"]
  end



  def show(conn, %{"id" => id}) do

    episode = Repo.get(Episode, id)
              |> Repo.preload([:podcast, :chapters, [recommendations: :user], :enclosures, :gigs,
                               :contributors])

    render conn, "show.json-api", data: episode,
                                  opts: [include: "podcast,chapters,recommendations,enclosures,gigs,contributors"]
  end
end
