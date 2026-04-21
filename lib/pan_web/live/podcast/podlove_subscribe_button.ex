defmodule PanWeb.Live.Podcast.PodloveSubscribeButton do
  use PanWeb, :live_component
  alias Phoenix.HTML

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

  attr :podcast, :map, required: true
  attr :class, :string, default: ""

  def render(assigns) do
    ~H"""
    <div id="subscribe-button"
         class={@class}
         phx-hook="PodloveSubscribeButton" />
    """
  end
end
