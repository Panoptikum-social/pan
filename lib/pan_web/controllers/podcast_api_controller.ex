defmodule PanWeb.PodcastApiController do
  use Pan.Web, :controller
  use JaSerializer
  alias PanWeb.Episode
  alias PanWeb.Podcast

  def index(conn, params) do
    page = Map.get(params, "page", %{})
           |> Map.get("number", "1")
           |> String.to_integer
    size = Map.get(params, "page", %{})
           |> Map.get("size", "10")
           |> String.to_integer
    offset = (page - 1) * size

    total = from(p in Podcast, where: is_nil(p.blocked) or p.blocked == false)
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

    total = from(p in Podcast, where: (is_nil(p.blocked) or p.blocked == false) and
                                      is_nil(p.latest_episode_publishing_date) == false and
                                      p.latest_episode_publishing_date < ^NaiveDateTime.utc_now())
            |> Repo.aggregate(:count, :id)
    total_pages = div(total - 1, size) + 1

    links = JaSerializer.Builder.PaginationLinks.build(%{number: page,
                                                         size: size,
                                                         total: total_pages,
                                                         base_url: podcast_api_url(conn,:last_updated)}, conn)

    podcasts = from(p in Podcast, where: (is_nil(p.blocked) or p.blocked == false) and
                                         is_nil(p.latest_episode_publishing_date) == false and
                                         p.latest_episode_publishing_date < ^NaiveDateTime.utc_now(),
                                  order_by: [desc: :latest_episode_publishing_date],
                                  limit: ^size,
                                  offset: ^offset)
               |> Repo.all()

    render conn, "index.json-api", data: podcasts,
                                   opts: [page: links]
  end


  def most_subscribed(conn, _params) do
    podcasts = from(p in Podcast, order_by: [desc: p.subscriptions_count],
                                  limit: 10)
               |> Repo.all()

    render conn, "index.json-api", data: podcasts
  end


  def most_liked(conn, _params) do
    podcasts = from(p in Podcast, order_by: [desc: p.likes_count],
                                  limit: 10)
               |> Repo.all()

    render conn, "index.json-api", data: podcasts
  end
end
