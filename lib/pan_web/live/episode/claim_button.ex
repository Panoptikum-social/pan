defmodule PanWeb.Live.Episode.ClaimButton do
  use Surface.LiveComponent
  alias PanWeb.Surface.EventButton
  alias PanWeb.Gig

  prop(current_user_id, :integer, required: true)
  prop(persona, :map, required: true)
  prop(episode_id, :integer, required: true)
  data(not_claimed_yet, :boolean)

  def handle_event("toggle-claim", _params, %{assigns: assigns} = socket) do
    Gig.proclaim(
      socket.assigns.episode_id,
      socket.assigns.persona.id,
      socket.assigns.current_user_id
    )

    {:noreply, assign(socket, not_claimed_yet: !assigns.not_claimed_yet)}
  end

  def render(assigns) do
    not_claimed_yet = Gig.find_self_proclaimed(assigns.persona.id, assigns.episode_id) |> is_nil
    assign(assigns, not_claimed_yet: not_claimed_yet)

    ~F"""
    <span>
      {#if @not_claimed_yet}
        <EventButton event="toggle-claim"
                     alt={"Claim contribution for #{@persona.pid}"}
                     icon="user-plus"
                     title={@persona.name} />
      {#else}
        <EventButton event="toggle-claim"
                     alt={"Withdraw contribution for #{@persona.pid}"}
                     icon="user-times"
                     title={@persona.name} />
      {/if}
    </span>
    """
  end
end
