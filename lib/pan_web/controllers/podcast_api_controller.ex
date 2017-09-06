defmodule PanWeb.PodcastApiController do
  use Pan.Web, :controller
  use JaSerializer
  alias PanWeb.Episode
  alias PanWeb.Podcast
  alias PanWeb.Subscription
  alias PanWeb.Like

  def index(conn, params) do
    page = Map.get(params, "page", %{})
           |> Map.get("number", "1")
           |> String.to_integer
    size = Map.get(params, "page", %{})
           |> Map.get("size", "10")
           |> String.to_integer
    offset = (page - 1) * size

    total = from(p in Podcast, where: is_nil(p.blocked) or p.blocked == false,)
            |> Repo.aggregate(:count, :id)
    total_pages = div(total - 1, size) + 1

    links = JaSerializer.Builder.PaginationLinks.build(%{number: page,
                                                         size: size,
                                                         total: total_pages,
                                                         base_url: podcast_api_url(conn,:index)}, conn)

    podcasts = from(p in Podcast, order_by: [desc: :inserted_at],
                                  where: is_nil(p.blocked) or p.blocked == false,
                                  preload: [:categories, :languages, :engagements, :contributors],
                                  limit: ^size,
                                  offset: ^offset)
               |> Repo.all()

    render conn, "index.json-api", data: podcasts,
                                   opts: [page: links,
                                          include: "categories,engagements,contributors,languages"]
  end


  def show(conn, %{"id" => id} = params) do
    page = Map.get(params, "page", %{})
           |> Map.get("number", "1")
           |> String.to_integer
    size = Map.get(params, "page", %{})
           |> Map.get("size", "10")
           |> String.to_integer
    offset = (page - 1) * size

    total = from(e in PanWeb.Episode, where: e.podcast_id == ^id)
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

    total = Repo.aggregate(PanWeb.Podcast, :count, :id)
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


  def most_subscribed(conn, _params) do
    podcasts = from(s in Subscription, join: p in assoc(s, :podcast),
                                       group_by: p.id,
                                       select: p,
                                       order_by: [desc: count(s.podcast_id)],
                                       limit: 10)
                       |> Repo.all()

    render conn, "index.json-api", data: podcasts
  end


  def most_liked(conn, _params) do
    podcasts = from(l in Like, join: p in assoc(l, :podcast),
                               group_by: p.id,
                               select: p,
                               order_by: [desc: count(l.podcast_id)],
                               limit: 10)
               |> Repo.all()

    render conn, "index.json-api", data: podcasts
  end
end
