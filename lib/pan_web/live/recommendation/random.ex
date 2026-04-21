defmodule PanWeb.Live.Recommendation.Random do
  use PanWeb, :live_view
  alias PanWeb.Component.EpisodeButton
  alias PanWeb.Component.PodcastButton
  alias PanWeb.Component.CategoryButton
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
      ~H"""
      <h1 class="text-3xl">A Random Recommendation</h1>
      <p class="mt-4 leading-9">
        Fortuna opted for the episode &nbsp; <EpisodeButton.render for={@episode} /> &nbsp;
        from the podcast  &nbsp; <PodcastButton.render for={@podcast} /> &nbsp;
        in the category  &nbsp;<CategoryButton.render for={@category} /> &nbsp;.
      </p>
      """
    else
      ~H"""
      <h1 class="text-3xl">A Random Recommendation</h1>
      <p class="mt-4 leading-9">
        loading ...
      </p>
      """
    end
  end
end
