defmodule PanWeb.Live.Recommendation.Random do
  use Surface.LiveView, container: {:div, class: "m-4"}
  alias PanWeb.Surface.{PodcastButton, EpisodeButton, CategoryButton}
  alias PanWeb.{Podcast, Category}

  def mount(_params, _session, socket) do
    if connected?(socket) do
      podcast = Podcast.random()
      category = List.first(podcast.categories).id |> Category.get_by_id()
      episode = Enum.random(podcast.episodes)

      {:ok,
       assign(socket,
         podcast: podcast,
         episode: episode,
         category: category,
         page_title: "Random Recommendation"
       )}
    else
      {:ok, assign(socket, page_title: "Random Recommendation")}
    end
  end

  def render(assigns) do
    if Map.has_key?(assigns, :podcast) do
      ~F"""
      <h1 class="text-3xl">A Random Recommendation</h1>
      <p class="mt-4 leading-9">
        Fortuna opted for the episode &nbsp; <EpisodeButton for={@episode} /> &nbsp;
        from the podcast  &nbsp; <PodcastButton for={@podcast} /> &nbsp;
        in the category  &nbsp;<CategoryButton for={@category} /> &nbsp;.
      </p>
      """
    else
      ~F"""
      <h1 class="text-3xl">A Random Recommendation</h1>
      <p class="mt-4 leading-9">
        loading ...
      </p>
      """
    end
  end
end
