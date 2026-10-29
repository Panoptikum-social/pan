defmodule PanWeb.Live.Episode.ClaimButton do
  use PanWeb, :live_component
  alias PanWeb.Component.EventButton
  alias PanWeb.{Gig, Episode}

  def mount(socket) do
    {:ok, assign(socket, not_claimed_yet: false)}
  end

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

  attr :current_user_id, :integer, required: true
  attr :persona, :map, required: true
  attr :episode_id, :integer, required: true
  attr :caller, :atom, default: nil
  attr :caller_id, :integer, default: nil

  def render(assigns) do
    ~H"""
    <span>
      <EventButton.render
        :if={@not_claimed_yet}
        event="toggle-claim"
        target={@myself}
        class="btn-outline btn-secondary"
        alt={"Claim contribution for #{@persona.pid}"}
        icon="user-plus"
        title={@persona.name}
      />
      <EventButton.render
        :if={!@not_claimed_yet}
        event="toggle-claim"
        target={@myself}
        class="btn-outline btn-secondary"
        alt={"Withdraw contribution for #{@persona.pid}"}
        icon="user-minus"
        title={@persona.name}
      />
    </span>
    """
  end
end
