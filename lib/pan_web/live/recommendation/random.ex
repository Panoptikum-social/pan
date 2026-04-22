defmodule PanWeb.Live.Recommendation.Random do
  use PanWeb, :live_view
  alias PanWeb.Component.EpisodeButton
  alias PanWeb.Component.PodcastButton
  alias PanWeb.Component.CategoryButton
  alias PanWeb.{Podcast, Category}

  def mount(_params, _session, socket) do
    if connected?(socket) do
      recommendations =
        Podcast.random(12)
        |> Enum.map(fn podcast ->
          category = List.first(podcast.categories).id |> Category.get_by_id()
          episode = Enum.random(podcast.episodes)
          %{podcast: podcast, episode: episode, category: category}
        end)

      {:ok,
       assign(socket,
         recommendations: recommendations,
         page_title: "A Dozen Random Recommendations"
       )}
    else
      {:ok, assign(socket, page_title: "A Dozen Random Recommendations")}
    end
  end

  def render(assigns) do
    if Map.has_key?(assigns, :recommendations) do
      ~H"""
      <div class="m-4">
        <h1 class="text-3xl">A Dozen Random Recommendations</h1>
        <p :for={r <- @recommendations} class="mt-4 leading-9">
          Fortuna opted for the episode &nbsp; <EpisodeButton.render for={r.episode} /> &nbsp;
          from the podcast &nbsp; <PodcastButton.render for={r.podcast} /> &nbsp;
          in the category &nbsp;<CategoryButton.render for={r.category} /> &nbsp;.
        </p>
      </div>
      """
    else
      ~H"""
      <div class="m-4">
        <h1 class="text-3xl">A Dozen Random Recommendations</h1>
        <p class="mt-4 leading-9">loading ...</p>
      </div>
      """
    end
  end
end
