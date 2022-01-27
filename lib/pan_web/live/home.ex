defmodule PanWeb.Live.Home do
  use Surface.LiveView, container: {:div, class: "flex-1 justify-self-center m-2"}
  import PanWeb.Router.Helpers
  alias PanWeb.Surface.{Panel, TopList, Tab, PodcastCard, EpisodeCard, RecommendationCard}
  alias Surface.Components.Link
  alias PanWeb.{Podcast, Episode, Recommendation}

  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       popular_podcasts: Podcast.popular,
       liked_podcasts: Podcast.liked,
       latest_podcasts: Podcast.latest,
       latest_episodes: Episode.latest,
       latest_recommendations: Recommendation.latest,
       page_title: "The Podcast Panoptikum "
     )}
  end
end
