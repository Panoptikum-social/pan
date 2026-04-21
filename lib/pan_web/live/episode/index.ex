defmodule PanWeb.Live.Episode.Index do
  use PanWeb, :live_view
  alias PanWeb.Episode
  alias PanWeb.Component.Panel
  alias PanWeb.Component.PodcastButton
  alias PanWeb.Component.EpisodeCard

  def mount(_params, _session, socket) do
    socket = assign(socket, page: 1, per_page: 15, page_title: "Latest Episodes")
    {:ok, stream(socket, :latest_episodes, Episode.latest(1, 15))}
  end

  def handle_event("load-more", _, %{assigns: assigns} = socket) do
    page = assigns.page + 1
    {:noreply, socket |> assign(page: page) |> stream(:latest_episodes, Episode.latest(page, assigns.per_page))}
  end

  def render(assigns) do
    ~H"""
    <Panel.render heading="Latest Episodes" purpose="episode" class="m-4">
      <div id="latest_episodes" phx-update="stream" class="m-2 grid md:grid-cols-2 2xl:grid-cols-3 gap-4">
        <div :for={{dom_id, episode} <- @streams.latest_episodes} id={dom_id} class="p-2 rounded-xl shadow">
          <p class="mb-1">Podcast <PodcastButton.render id={episode.podcast_id} title={episode.podcast_title} /></p>
          <EpisodeCard.render for={episode}/>
        </div>
      </div>
      <div id="infinite-scroll" phx-hook="InfiniteScroll" data-page={@page}></div>
    </Panel.render>
    """
  end
end
