defmodule PanWeb.Live.Podcast.Subscribe do
  use Surface.LiveView
  alias PanWeb.Podcast
  alias PanWeb.Live.Podcast.PodloveSubscribeButton

  def mount(%{"id" => id}, _session, socket) do
    {:ok, assign(socket, podcast: Podcast.get_by_id_with_feeds(id))}
  end

  def render(assigns) do
    ~F"""
    <PodloveSubscribeButton id="podlove_subscribe_button"
                            {=@podcast}
                            class="grid place-items-center h-screen" />
    """
  end
end
