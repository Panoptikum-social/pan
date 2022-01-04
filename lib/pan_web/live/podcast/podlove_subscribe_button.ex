defmodule PanWeb.Live.Podcast.PodloveSubscribeButton do
  use Surface.LiveComponent
  alias Phoenix.HTML

  prop(podcast, :map, required: true)
  prop(class, :css_class, default: "", required: false)

  def handle_event("read-config", _, socket) do
    podcast = socket.assigns.podcast
    config = %{
      title: HTML.javascript_escape(podcast.title || ""),
      subtitle: HTML.javascript_escape(podcast.summary || ""),
      description: HTML.javascript_escape(podcast.description || ""),
      cover: podcast.image_url,
      feeds: feed_config(podcast.feeds)
    }

    {:reply, config, socket}
  end

  defp feed_config(feeds) do
    Enum.map(feeds, fn feed ->
      %{type: "audio", format: "mp3", url: feed.self_link_url, variant: "high"}
    end)
  end

  def render(assigns) do
    ~F"""
    <div id="subscribe-button"
         class={@class}
         :hook="PodloveSubscribeButton" />
    """
  end
end
