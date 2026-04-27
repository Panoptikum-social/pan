defmodule PanWeb.Live.Category.LatestEpisodes do
  use PanWeb, :live_view
  alias PanWeb.{Category, Podcast, Episode}
  alias PanWeb.Component.Panel
  alias PanWeb.Component.PodcastButton
  alias PanWeb.Component.EpisodeCard

  def mount(%{"id" => id}, _session, socket) do
    podcast_ids = Podcast.ids_by_category_id(id)
    category = Category.get_by_id_with_parent(id)

    episodes = Episode.latest_episodes_by_podcast_ids(podcast_ids, 1, 15)

    socket =
      assign(socket,
        page: 1,
        per_page: 15,
        category: category,
        podcast_ids: podcast_ids,
        page_title: "Latest Episodes in #{category.title} (Category)",
        has_more: length(episodes) == 15
      )

    {:ok, stream(socket, :latest_episodes, episodes)}
  end

  def handle_event("load-more", _, %{assigns: assigns} = socket) do
    page = assigns.page + 1
    episodes = Episode.latest_episodes_by_podcast_ids(assigns.podcast_ids, page, assigns.per_page)
    {:noreply, socket |> assign(page: page, has_more: length(episodes) == assigns.per_page) |> stream(:latest_episodes, episodes)}
  end

  def render(assigns) do
    ~H"""
    <Panel.render heading={"Latest Episodes for #{@category.title}"} purpose="episode" class="m-4">
      <div id="latest_episodes" phx-update="stream" class="m-2 grid md:grid-cols-2 2xl:grid-cols-3 gap-4">
        <div :for={{dom_id, episode} <- @streams.latest_episodes} id={dom_id} class="my-2">
          <p class="mb-1">Podcast <PodcastButton.render id={episode.podcast_id} title={episode.podcast_title} /></p>
          <EpisodeCard.render for={episode}/>
        </div>
      </div>
      <div :if={@has_more} id="infinite-scroll" phx-hook="InfiniteScroll" data-page={@page}></div>
    </Panel.render>
    """
  end
end
