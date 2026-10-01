defmodule PanWeb.Live.Moderation.Curators do
  use PanWeb, :live_view
  on_mount PanWeb.Live.AssignUserAndAdmin
  alias PanWeb.Component.CuratorAssignment
  alias PanWeb.{Curatorship, Moderation}

  def mount(_params, _session, socket) do
    community_ids = Moderation.community_ids_of_user(socket.assigns.current_user_id)

    {:ok, socket |> assign(community_ids: community_ids) |> fetch()}
  end

  defp fetch(socket),
    do: assign(socket, entries: Curatorship.assignment_list(socket.assigns.community_ids))

  # Moderators may only change the communities they moderate.
  def handle_event(event, %{"community_id" => community_id} = params, socket) do
    community_id = String.to_integer(community_id)

    if community_id in socket.assigns.community_ids do
      {:noreply, change(event, community_id, params, socket) |> fetch()}
    else
      {:noreply, put_flash(socket, :error, "You do not moderate this community.")}
    end
  end

  defp change("assign", community_id, %{"user_id" => user_id}, socket) do
    case Curatorship.assign(community_id, String.to_integer(user_id)) do
      {:ok, _} -> put_flash(socket, :info, "Curator assigned.")
      {:error, _} -> put_flash(socket, :error, "Assigning failed.")
    end
  end

  defp change("assign_by_username", community_id, %{"username" => username}, socket) do
    case Curatorship.make_curator_and_assign(community_id, username) do
      {:ok, _} -> put_flash(socket, :info, "#{username} is now a curator of this community.")
      {:error, :user_not_found} -> put_flash(socket, :error, "No user \"#{username}\" found.")
      {:error, _} -> put_flash(socket, :error, "Assigning failed.")
    end
  end

  defp change("unassign", community_id, %{"user_id" => user_id}, socket) do
    Curatorship.unassign(community_id, String.to_integer(user_id))
    put_flash(socket, :info, "Curator removed.")
  end

  def render(assigns) do
    ~H"""
    <div class="m-4">
      <h1 class="text-3xl">Curators of my communities</h1>

      <p class="my-2">
        Pick an existing curator, or make any user a curator by their username. Removing a
        curator keeps their curations; only admins can take the curator role away.
      </p>

      <CuratorAssignment.render entries={@entries} by_username />
    </div>
    """
  end
end
