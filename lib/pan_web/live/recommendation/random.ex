defmodule PanWeb.Live.Recommendation.Random do
  use Surface.LiveView
  alias PanWeb.Surface.{PodcastButton, EpisodeButton, CategoryButton}
  alias PanWeb.{Podcast, Category}

  def mount(_params, _session, socket) do
    podcast = Podcast.random
    category = List.first(podcast.categories).id |> Category.get_by_id()
    episode = Enum.random(podcast.episodes)

    {:ok, assign(socket, podcast: podcast, episode: episode, category: category)}
  end

  def render(assigns) do
    ~F"""
    <p class="m-4">
      Fortuna opted for the episode &nbsp; <EpisodeButton for={@episode} /> &nbsp;
      from the podcast  &nbsp; <PodcastButton for={@podcast} /> &nbsp;
      in the category  &nbsp;<CategoryButton for={@category} /> &nbsp;.
    </p>
    """
  end
end
