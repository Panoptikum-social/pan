defmodule PanWeb.Live.Category.FollowButton do
  use Surface.LiveComponent
  alias PanWeb.{Follow, Category}
  alias PanWeb.Surface.Icon

  prop(current_user_id, :integer, required: true)
  prop(category, :map, required: true)
  data(following, :boolean, default: false)
  data(followers_count, :integer, default: 0)

  def handle_event("toggle-follow", _params, %{assigns: assigns} = socket) do
    Category.follow(assigns.category.id, assigns.current_user_id)

    socket =
      assign(socket,
        following: !assigns.following,
        category: Category.get_by_id(assigns.category.id),
        followers_count: Category.follows(assigns.category.id)
      )

    {:noreply, socket}
  end

  def render(assigns) do
    following =
      Follow.find_category_follow(assigns.current_user_id, assigns.category.id)
      |> is_nil
      |> Kernel.not()

    assigns =
      assign(assigns,
        following: following,
        followers_count: Category.follows(assigns.category.id)
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
