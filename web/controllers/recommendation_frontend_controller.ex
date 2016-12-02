defmodule Pan.RecommendationFrontendController do
  use Pan.Web, :controller
  alias Pan.Podcast
  alias Pan.Episode
  alias Pan.Category

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
end
