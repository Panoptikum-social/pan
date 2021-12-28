defmodule PanWeb.Live.User.FollowButton do
  use Surface.LiveComponent
  alias PanWeb.{Follow, User}
  alias PanWeb.Surface.Icon

  prop(current_user_id, :integer, required: true)
  prop(user, :map, required: true)
  data(following, :boolean, default: false)
  data(followers_count, :integer, default: 0)

  def handle_event("toggle-follow", _params, %{assigns: assigns} = socket) do
    User.follow(assigns.user.id, assigns.current_user_id)

    socket =
      assign(socket,
        following: !assigns.following,
        user: User.get_by_id(assigns.user.id),
        followers_count: User.follows(assigns.user.id)
      )

    {:noreply, socket}
  end

  def render(assigns) do
    following =
      Follow.find_user_follow(assigns.current_user_id, assigns.user.id)
      |> is_nil
      |> Kernel.not()

    assigns =
      assign(assigns,
        following: following,
        followers_count: User.follows(assigns.user.id)
      )

    ~F"""
    <span>
      {#if @following}
        <button :on-click="toggle-follow"
                class="text-white rounded py-1 px-2 bg-success border border-gray-darker rounded">
          {@followers_count} <Icon name="chat-heroicons-solid"/> Unfollow
        </button>
      {#else}
        <button :on-click="toggle-follow"
                class="text-white rounded py-1 px-2 bg-danger border border-gray-darker rounded">
          {@followers_count} <Icon name="chat-heroicons-outline"/> Follow
        </button>
      {/if}
    </span>
    """
  end
end
