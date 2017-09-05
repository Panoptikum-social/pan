defmodule Pan.RecommendationApiController do
  use Pan.Web, :controller
  alias Pan.Recommendation
  alias Pan.Podcast
  alias Pan.Category
  alias Pan.Episode
  use JaSerializer


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
                     |> Map.put(:user, %Pan.User{id: 1, name: "Fortuna"})

    render conn, "show.json-api", data: recommendation,
                                  opts: [include: "podcast,episode,category"]

  end
end

