defmodule PanWeb.RecommendationApiController do
  use Pan.Web, :controller
  alias PanWeb.Recommendation
  alias PanWeb.Podcast
  alias PanWeb.Category
  alias PanWeb.Episode
  use JaSerializer

  def index(conn, params) do
    page = Map.get(params, "page", %{})
           |> Map.get("number", "1")
           |> String.to_integer
    size = Map.get(params, "page", %{})
           |> Map.get("size", "10")
           |> String.to_integer
    offset = (page - 1) * size

    total = Repo.aggregate(Recommendation, :count, :id)
    total_pages = div(total - 1, size) + 1

    links = JaSerializer.Builder.PaginationLinks.build(%{number: page,
                                                         size: size,
                                                         total: total_pages,
                                                         base_url: episode_api_url(conn,:index)}, conn)

    recommendations = from(e in Recommendation, order_by: [desc: :inserted_at],
                                                preload: [:podcast, :episode, :chapter, :user],
                                                limit: ^size,
                                                offset: ^offset)
               |> Repo.all()

    render conn, "index.json-api", data: recommendations,
                                   opts: [page: links,
                                          include: "podcast,episode,chapter,user"]
  end


  def show(conn, %{"id" => id}) do
    recommendation = Repo.get(Recommendation, id)
                     |> Repo.preload([:podcast, :episode, :chapter, :user])

    render conn, "show.json-api", data: recommendation,
                                  opts: [include: "podcast,episode,chapter,user"]
  end


  def random(conn, _params) do
    podcast = from(p in Podcast, order_by: fragment("RANDOM()"),
                                 limit: 1,
                                 preload: [:episodes, :languages, :categories, :feeds, engagements: :persona])
              |> Repo.one()

    category = Repo.get(Category, List.first(podcast.categories).id)
               |> Repo.preload([:parent, :children, :podcasts])

    episode = Enum.random(podcast.episodes)
    episode = Repo.get(Episode, episode.id)
              |> Repo.preload([:podcast, :enclosures, [chapters: :recommendations],
                               :contributors, :recommendations, [gigs: :persona]])

    recommendation = %Recommendation{podcast_id: podcast.id,
                                     episode_id: episode.id,
                                     id: "random"}
                     |> Map.put(:podcast, podcast)
                     |> Map.put(:episode, episode)
                     |> Map.put(:category, category)
                     |> Map.put(:chapter, %{})
                     |> Map.put(:user, %PanWeb.User{id: 1, name: "Fortuna"})

    render conn, "show.json-api", data: recommendation,
                                  opts: [include: "podcast,episode,category"]

  end
end
