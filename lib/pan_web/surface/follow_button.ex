defmodule PanWeb.Surface.FollowButton do
  use Surface.LiveComponent
  alias PanWeb.{Follow, User, Podcast, Category, Persona}
  alias PanWeb.Surface.Icon

  prop(current_user_id, :integer, required: true)
  prop(instance, :map, required: true)
  prop(model, :module, required: true)
  data(following, :boolean, default: false)
  data(followers_count, :integer, default: 0)

  def update(assigns, socket) do
    follow_method =
      case assigns.model do
        Podcast -> &Follow.find_podcast_follow/2
        Category -> &Follow.find_category_follow/2
        Persona -> &Follow.find_persona_follow/2
        User -> &Follow.find_user_follow/2
      end

    following =
      follow_method.(assigns.current_user_id, assigns.instance.id)
      |> is_nil
      |> Kernel.not()

    socket =
      assign(socket, assigns)
      |> assign(following: following, followers_count: assigns.model.follows(assigns.instance.id))

    {:ok, socket}
  end

  def handle_event("toggle-follow", _params, %{assigns: assigns} = socket) do
    assigns.model.follow(assigns.instance.id, assigns.current_user_id)

    socket =
      assign(socket,
        following: !assigns.following,
        instance: assigns.model.get_by_id(assigns.instance.id),
        followers_count: assigns.model.follows(assigns.instance.id)
      )

    {:noreply, socket}
  end

  def render(assigns) do
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
