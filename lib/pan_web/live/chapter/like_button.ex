defmodule PanWeb.Live.Chapter.LikeButton do
  use Surface.LiveComponent
  alias PanWeb.{Like, Chapter}
  alias PanWeb.Surface.Icon

  prop(current_user_id, :integer, required: true)
  prop(chapter, :map, required: true)
  data(liking, :boolean, default: false)

  def handle_event("toggle-like", _params, %{assigns: assigns} = socket) do
    Chapter.like(assigns.chapter.id, assigns.current_user_id)

    socket =
      assign(socket,
        liking: !assigns.liking,
        chapter: Chapter.get_by_id(assigns.chapter.id)
      )

    {:noreply, socket}
  end

  def render(assigns) do
    liking =
      Like.find_chapter_like(assigns.current_user_id, assigns.chapter.id)
      |> is_nil
      |> Kernel.not()

    assigns = assign(assigns, liking: liking)

    ~F"""
      <span>
        {#if @liking}
          <button :on-click="toggle-like"
                  class="text-white rounded py-1 px-2 bg-success border border-gray-darker rounded">
            {@chapter.likes_count} <Icon name="heart-heroicons-solid"/> Unlike
          </button>
        {#else}
          <button :on-click="toggle-like"
                  class="text-white rounded py-1 px-2 bg-danger border border-gray-darker rounded">
            {@chapter.likes_count} <Icon name="heart-heroicons-outline"/> Like
          </button>
        {/if}
      </span>
    """
  end
end
