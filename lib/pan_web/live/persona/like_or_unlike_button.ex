defmodule PanWeb.Live.Persona.LikeOrUnlikeButton do
  use Surface.LiveComponent
  alias PanWeb.{Like, Persona}
  alias PanWeb.Surface.Icon

  prop(current_user_id, :integer, required: true)
  prop(persona, :map, required: true)
  data(liking, :boolean, default: false)
  data(likes_count, :integer, default: 0)

  def handle_event("toggle-like", _params, %{assigns: assigns} = socket) do
    Persona.like(assigns.persona.id, assigns.current_user_id)

    socket =
      assign(socket,
        liking: !assigns.liking,
        user: Persona.get_by_id(assigns.persona.id),
        likes_count: Persona.likes(assigns.persona.id)
      )

    {:noreply, socket}
  end

  def render(assigns) do
    liking =
      Like.find_persona_like(assigns.current_user_id, assigns.persona.id)
      |> is_nil
      |> Kernel.not()

    assigns =
      assign(assigns,
        liking: liking,
        likes_count: Persona.likes(assigns.persona.id)
      )

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
