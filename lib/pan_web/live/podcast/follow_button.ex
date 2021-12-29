defmodule PanWeb.Live.Podcast.FollowButton do
  use Surface.LiveComponent
  alias PanWeb.{Follow, Podcast}
  alias PanWeb.Surface.Icon

  prop(current_user_id, :integer, required: true)
  prop(podcast, :map, required: true)
  data(following, :boolean, default: false)

  def update(assigns, socket) do
    following =
      Follow.find_podcast_follow(assigns.current_user_id, assigns.podcast.id)
      |> is_nil
      |> Kernel.not()

    socket =
      assign(socket, assigns)
      |> assign(following: following)

    {:ok, socket}
  end

  def handle_event("toggle-follow", _params, %{assigns: assigns} = socket) do
    Podcast.follow(assigns.podcast.id, assigns.current_user_id)

    socket =
      assign(socket,
        following: !assigns.following,
        podcast: Podcast.get_by_id(assigns.podcast.id)
      )

    {:noreply, socket}
  end

  def render(assigns) do
    ~F"""
      <span>
        {#if @following}
          <button :on-click="toggle-follow"
                  class="text-white rounded py-1 px-2 bg-success border border-gray-darker rounded">
            {@podcast.followers_count} <Icon name="chat-heroicons-solid"/> Unfollow
          </button>
        {#else}
          <button :on-click="toggle-follow"
                  class="text-white rounded py-1 px-2 bg-danger border border-gray-darker rounded">
            {@podcast.followers_count} <Icon name="chat-heroicons-outline"/> Follow
          </button>
        {/if}
      </span>
    """
  end
end
