defmodule PanWeb.Component.LikeButton do
  use PanWeb, :live_component
  alias PanWeb.{Like, Chapter, Episode, Podcast, Persona, Category, User}
  alias PanWeb.Component.Icon

  def update(assigns, socket) do
    like_method =
      case assigns.model do
        Chapter  -> &Like.find_chapter_like/2
        Episode  -> &Like.find_episode_like/2
        Podcast  -> &Like.find_podcast_like/2
        Category -> &Like.find_category_like/2
        Persona  -> &Like.find_persona_like/2
        User     -> &Like.find_user_like/2
      end

    liking =
      like_method.(assigns.current_user_id, assigns.instance.id)
      |> is_nil
      |> Kernel.not()

    socket =
      assign(socket, assigns)
      |> assign(liking: liking, likes_count: assigns.model.likes(assigns.instance.id))

    {:ok, socket}
  end

  def handle_event("toggle-like", _params, %{assigns: assigns} = socket) do
    assigns.model.like(assigns.instance.id, assigns.current_user_id)

    socket =
      assign(socket,
        liking: !assigns.liking,
        chapter: assigns.model.get_by_id(assigns.instance.id),
        likes_count: assigns.model.likes(assigns.instance.id)
      )

    {:noreply, socket}
  end

  attr :id, :string, default: nil
  attr :current_user_id, :integer, required: true
  attr :instance, :map, required: true
  attr :model, :atom, required: true

  def render(assigns) do
    ~H"""
    <span>
      <%= if @liking do %>
        <button phx-click="toggle-like"
                phx-target={@myself}
                class="text-white rounded py-1 px-2 bg-success border border-gray-darker my-2">
          {@likes_count} <Icon.render name="heart-heroicons-solid" /> Unlike
        </button>
      <% else %>
        <button phx-click="toggle-like"
                phx-target={@myself}
                class="text-white rounded py-1 px-2 bg-danger border border-gray-darker my-2">
          {@likes_count} <Icon.render name="heart-heroicons-outline" /> Like
        </button>
      <% end %>
    </span>
    """
  end
end
