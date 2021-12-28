defmodule PanWeb.Live.Episode.LikeButton do
  use Surface.LiveComponent
  alias PanWeb.{Like, Episode}
  alias PanWeb.Surface.Icon

  prop(current_user_id, :integer, required: true)
  prop(episode, :map, required: true)
  data(liking, :boolean, default: false)
  data(likes_count, :integer, default: 0)

  def handle_event("toggle-like", _params, %{assigns: assigns} = socket) do
    Episode.like(assigns.episode.id, assigns.current_user_id)

    socket =
      assign(socket,
        liking: !assigns.liking,
        episode: Episode.get_by_id(assigns.episode.id),
        likes_count: Episode.likes(assigns.episode.id)
      )

    {:noreply, socket}
  end

  def render(assigns) do
    liking =
      Like.find_episode_like(assigns.current_user_id, assigns.episode.id)
      |> is_nil
      |> Kernel.not()

    assigns = assign(assigns, liking: liking, likes_count: Episode.likes(assigns.episode.id))

    ~F"""
      <span>
        {#if @liking}
          <button :on-click="toggle-like"
                  class="text-white rounded py-1 px-2 bg-success border border-gray-darker rounded">
            {@likes_count} <Icon name="heart-heroicons-solid"/> Unlike
          </button>
        {#else}
          <button :on-click="toggle-like"
                  class="text-white rounded py-1 px-2 bg-danger border border-gray-darker rounded">
            {@likes_count} <Icon name="heart-heroicons-outline"/> Like
          </button>
        {/if}
      </span>
    """
  end
end
