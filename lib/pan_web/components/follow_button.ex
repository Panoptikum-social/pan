defmodule PanWeb.Component.FollowButton do
  use PanWeb, :live_component
  alias PanWeb.{Follow, User, Podcast, Category, Persona}
  alias PanWeb.Component.Icon

  def update(assigns, socket) do
    follow_method =
      case assigns.model do
        Podcast  -> &Follow.find_podcast_follow/2
        Category -> &Follow.find_category_follow/2
        Persona  -> &Follow.find_persona_follow/2
        User     -> &Follow.find_user_follow/2
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

  attr :current_user_id, :integer, required: true
  attr :instance, :map, required: true
  attr :model, :atom, required: true

  def render(assigns) do
    ~H"""
    <span>
      <%= if @following do %>
        <button phx-click="toggle-follow"
                phx-target={@myself}
                class="text-white rounded py-1 px-2 bg-success border border-gray-darker my-2">
          {@followers_count} <Icon.render name="chat-heroicons-solid" /> Unfollow
        </button>
      <% else %>
        <button phx-click="toggle-follow"
                phx-target={@myself}
                class="text-white rounded py-1 px-2 bg-danger border border-gray-darker my-2">
          {@followers_count} <Icon.render name="chat-heroicons-outline" /> Follow
        </button>
      <% end %>
    </span>
    """
  end
end
