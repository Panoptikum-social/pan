defmodule Pan.RecommendationFrontendController do
  use Pan.Web, :controller
  alias Pan.Podcast
  alias Pan.Episode
  alias Pan.Category
  alias Pan.Recommendation

  def random(conn, _params) do
    category = Repo.all(Category)
               |> Enum.random

    category = Repo.get(Category, category.id)
               |> Repo.preload([:parent, :children, :podcasts])

    podcast = Enum.random(category.podcasts)
    podcast = Repo.get(Podcast, podcast.id)
              |> Repo.preload([:episodes, :languages, :owner, :categories, :feeds])

    episode = Enum.random(podcast.episodes)
    episode = Repo.get(Episode, episode.id)
              |> Repo.preload([:podcast, :enclosures, :chapters, :contributors])

    render(conn, "random.html", category: category,
                                podcast: podcast,
                                episode: episode,
                                player: "podigee")
  end


  def create(conn, %{"recommendation" => recommendation_params}) do
    recommendation_params = Map.put(recommendation_params, "user_id", conn.assigns.current_user.id)
    changeset = Recommendation.changeset(%Recommendation{}, recommendation_params)
    podcast_id = String.to_integer(recommendation_params["podcast_id"])

    Repo.insert(changeset)

    conn
    |> put_flash(:info, "Your recommendation has been added.")
    |> redirect(to: podcast_frontend_path(conn, :show, podcast_id))
  end
end
