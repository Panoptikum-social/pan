defmodule PanWeb.Live.Episode.ClaimButton do
  use Surface.LiveComponent
  alias PanWeb.Surface.EventButton
  alias PanWeb.{Gig, Episode}

  prop(current_user_id, :integer, required: true)
  prop(persona, :map, required: true)
  prop(episode_id, :integer, required: true)
  prop(caller, :module, required: false)
  prop(caller_id, :integer, required: false)
  data(not_claimed_yet, :boolean, default: false)

  def update(assigns, socket) do
    not_claimed_yet = Gig.find_self_proclaimed(assigns.persona.id, assigns.episode_id) |> is_nil

    socket =
      assign(socket, assigns)
      |> assign(not_claimed_yet: not_claimed_yet)

    {:ok, socket}
  end

  def handle_event("toggle-claim", _params, %{assigns: assigns} = socket) do
    Gig.proclaim(
      socket.assigns.episode_id,
      socket.assigns.persona.id,
      socket.assigns.current_user_id
    )

    if assigns.caller && assigns.caller_id do
      send_update(assigns.caller,
        id: assigns.caller_id,
        episode: Episode.get_by_id_for_episode_show(assigns.episode_id)
      )
    end

    {:noreply, assign(socket, not_claimed_yet: !assigns.not_claimed_yet)}
  end

  def render(assigns) do
    ~F"""
    <span>
      {#if @not_claimed_yet}
        <EventButton event="toggle-claim"
                     class="text-lavender border-lavender bg-white hover:bg-gray-lightest"
                     alt={"Claim contribution for #{@persona.pid}"}
                     icon="user-add-heroicons-outline"
                     title={@persona.name} />
      {#else}
        <EventButton event="toggle-claim"
                     class="text-white border-lavender bg-lavender hover:bg-lavender-light"
                     alt={"Withdraw contribution for #{@persona.pid}"}
                     icon="user-remove-heroicons-outline"
                     title={@persona.name} />
      {/if}
    </span>
    """
  end
end
