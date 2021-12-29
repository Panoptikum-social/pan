defmodule PanWeb.Live.Chapter.LikeButton do
  use Surface.LiveComponent
  alias PanWeb.{Like, Chapter}
  alias PanWeb.Surface.Icon

  prop(current_user_id, :integer, required: true)
  prop(chapter, :map, required: true)
  data(liking, :boolean, default: false)
  data(likes_count, :integer, default: 0)

  def update(assigns, socket) do
    liking =
      Like.find_chapter_like(assigns.current_user_id, assigns.chapter.id)
      |> is_nil
      |> Kernel.not()

    socket =
      assign(socket, assigns)
      |> assign(assigns, liking: liking)
      |> assign(assigns, likes_count: Chapter.likes(assigns.chapter.id))

    {:ok, socket}
  end

  def handle_event("toggle-like", _params, %{assigns: assigns} = socket) do
    Chapter.like(assigns.chapter.id, assigns.current_user_id)

    socket =
      assign(socket,
        liking: !assigns.liking,
        chapter: Chapter.get_by_id(assigns.chapter.id),
        likes_count: Chapter.likes(assigns.category.id)
      )

    {:noreply, socket}
  end

  def render(assigns) do
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
