defmodule PanWeb.Live.Podcast.Subscribe do
  use Surface.LiveView
  alias PanWeb.{Podcast, Image}
  alias PanWeb.Live.Podcast.PodloveSubscribeButton

  def mount(%{"id" => id}, _session, socket) do
    {:ok,
     assign(socket,
       podcast: Podcast.get_by_id_with_feeds(id),
       podcast_thumbnail: Image.get_by_podcast_id(id) || %{}
     )}
  end

  def render(assigns) do
    ~F"""
      <div class="flex flex-col h-screen space-y-4 justify-center items-center w-screen">
          <img :if={Map.has_key?(@podcast_thumbnail, :path)}
              src={"https://panoptikum.io#{@podcast_thumbnail.path}#{@podcast_thumbnail.filename}"}
              width="150"
              height="150"
              alt={@podcast.image_title}
              id="photo"
              class="break-words text-xs" />
          <PodloveSubscribeButton id="podlove_subscribe_button"
                                  {=@podcast} />
      </div>
    """
  end
end
