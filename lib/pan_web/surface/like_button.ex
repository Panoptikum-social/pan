defmodule PanWeb.Surface.LikeButton do
  use Surface.LiveComponent
  alias PanWeb.{Like, Chapter, Episode, Podcast, Persona, Category, User}
  alias PanWeb.Surface.Icon

  prop(current_user_id, :integer, required: true)
  prop(instance, :map, required: true)
  prop(model, :module, required: true)
  data(liking, :boolean, default: false)
  data(likes_count, :integer, default: 0)

  def update(assigns, socket) do
    like_method =
      case assigns.model do
        Chapter -> &Like.find_chapter_like/2
        Episode -> &Like.find_episode_like/2
        Podcast -> &Like.find_podcast_like/2
        Category -> &Like.find_category_like/2
        Persona -> &Like.find_persona_like/2
        User -> &Like.find_user_like/2
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

  def render(assigns) do
    ~F"""
      <span>
        {#if @liking}
          <button :on-click="toggle-like"
                  class="text-white rounded py-1 px-2 bg-success border border-gray-darker my-2">
            {@likes_count} <Icon name="heart-heroicons-solid"/> Unlike
          </button>
        {#else}
          <button :on-click="toggle-like"
                  class="text-white rounded py-1 px-2 bg-danger border border-gray-darker my-2">
            {@likes_count} <Icon name="heart-heroicons-outline"/> Like
          </button>
        {/if}
      </span>
    """
  end
end
