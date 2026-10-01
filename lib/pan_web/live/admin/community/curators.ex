defmodule PanWeb.Live.Admin.Community.Curators do
  use PanWeb, :admin_live_view
  alias PanWeb.Component.CuratorAssignment
  alias PanWeb.Curatorship

  def mount(_params, _session, socket) do
    {:ok, fetch(socket)}
  end

  defp fetch(socket), do: assign(socket, entries: Curatorship.assignment_list(:all))

  def handle_event("assign", %{"community_id" => community_id, "user_id" => user_id}, socket) do
    case Curatorship.assign(String.to_integer(community_id), String.to_integer(user_id)) do
      {:ok, _} -> {:noreply, socket |> put_flash(:info, "Curator assigned.") |> fetch()}
      {:error, _} -> {:noreply, socket |> put_flash(:error, "Assigning failed.") |> fetch()}
    end
  end

  def handle_event("unassign", %{"community_id" => community_id, "user_id" => user_id}, socket) do
    Curatorship.unassign(String.to_integer(community_id), String.to_integer(user_id))
    {:noreply, socket |> put_flash(:info, "Curator removed.") |> fetch()}
  end

  def render(assigns) do
    ~H"""
    <div class="m-4">
      <h1 class="text-3xl">Curators</h1>

      <p class="my-2">
        Only users with the curator flag can be assigned. Removing a curator keeps their curations.
      </p>

      <CuratorAssignment.render entries={@entries} />
    </div>
    """
  end
end
