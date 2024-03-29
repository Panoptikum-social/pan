defmodule PanWeb.Live.Episode.Player do
  use Surface.LiveView
  alias PanWeb.Episode
  alias PanWeb.Live.Episode.PodlovePlayer

  def mount(%{"id" => id}, _session, socket) do
    episode = Episode.get_by_id_for_episode_player(id)

    {:ok,
     assign(socket, episode: episode, page_title: "Player Page for #{episode.title} (Episode)")}
  end

  def render(assigns) do
    ~F"""
    <div class="h-full">
      <PodlovePlayer id="webplayer"
                     episode={@episode}
                     class="mx-auto max-w-screen-lg" />
    </div>
    """
  end
end
