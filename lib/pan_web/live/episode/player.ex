defmodule PanWeb.Live.Episode.Player do
  use PanWeb, :live_view
  alias PanWeb.Episode
  alias PanWeb.Live.Episode.PodlovePlayer

  def mount(%{"id" => id}, _session, socket) do
    episode = Episode.get_by_id_for_episode_player(id)

    {:ok,
     assign(socket, episode: episode, page_title: "Player Page for #{episode.title} (Episode)")}
  end

  def render(assigns) do
    ~H"""
    <div class="h-full">
      <.live_component module={PodlovePlayer}
                       id="webplayer"
                       episode={@episode}
                       class="mx-auto max-w-5xl" />
    </div>
    """
  end
end
