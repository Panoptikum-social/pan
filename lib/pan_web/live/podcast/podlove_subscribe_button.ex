defmodule PanWeb.Live.Podcast.PodloveSubscribeButton do
  use PanWeb, :live_component
  alias PanWeb.{Endpoint, Image}

  def handle_event("read-config", _, socket) do
    podcast = socket.assigns.podcast

    config = %{
      title: podcast.title || "",
      subtitle: podcast.summary || "",
      description: podcast.description || "",
      cover: cover_url(Image.get_by_podcast_id(podcast.id)),
      feeds: feed_config(podcast.feeds)
    }

    {:reply, config, socket}
  end

  # our thumbnail rather than the podcaster's image_url: the
  # Content-Security-Policy only allows images from our own host
  defp cover_url(%Image{path: path, filename: filename})
       when is_binary(path) and is_binary(filename),
       do: "https://panoptikum.social" <> path <> filename

  defp cover_url(_), do: Endpoint.url() <> "/images/missing-podcast.png"

  defp feed_config(feeds) do
    Enum.map(feeds, fn feed ->
      %{type: "audio", format: "mp3", url: feed.self_link_url, variant: "high"}
    end)
  end

  attr :podcast, :map, required: true
  attr :class, :string, default: ""

  def render(assigns) do
    ~H"""
    <div
      id="subscribe-button"
      class={@class}
      phx-hook="PodloveSubscribeButton"
    />
    """
  end
end
