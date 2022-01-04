defmodule PanWeb.Live.Podcast.LikeButton do
  use Surface.LiveComponent
  alias PanWeb.{Like, Podcast}
  alias PanWeb.Surface.Icon

  prop(current_user_id, :integer, required: true)
  prop(podcast, :map, required: true)
  data(liking, :boolean, default: false)

  def update(assigns, socket) do
    liking =
      Like.find_podcast_like(assigns.current_user_id, assigns.podcast.id)
      |> is_nil
      |> Kernel.not()

    socket =
      assign(socket, assigns)
      |> assign(liking: liking)

    {:ok, socket}
  end

  def handle_event("toggle-like", _params, %{assigns: assigns} = socket) do
    Podcast.like(assigns.podcast.id, assigns.current_user_id)

    socket =
      assign(socket,
        liking: !assigns.liking,
        podcast: Podcast.get_by_id(assigns.podcast.id)
      )

    {:noreply, socket}
  end

  def render(assigns) do
    ~F"""
      <span>
        {#if @liking}
          <button :on-click="toggle-like"
                  class="text-white rounded py-1 px-2 bg-success border border-gray-darker rounded">
            {@podcast.likes_count} <Icon name="heart-heroicons-solid"/> Unlike
          </button>
        {#else}
          <button :on-click="toggle-like"
                  class="text-white rounded py-1 px-2 bg-danger border border-gray-darker rounded">
            {@podcast.likes_count} <Icon name="heart-heroicons-outline"/> Like
          </button>
        {/if}
      </span>
    """
  end
end