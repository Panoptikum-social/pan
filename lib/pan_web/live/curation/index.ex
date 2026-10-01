defmodule PanWeb.Live.Curation.Index do
  use PanWeb, :live_view
  on_mount PanWeb.Live.AssignUserAndAdmin
  alias PanWeb.Curation
  alias PanWeb.Router.Helpers, as: Routes

  def mount(_params, _session, socket) do
    {:ok, assign(socket, communities: Curation.communities_for(socket.assigns.current_user_id))}
  end

  def render(assigns) do
    ~H"""
    <div class="m-4">
      <h1 class="text-3xl">My Curations</h1>

      <ul class="list-disc m-4">
        <li :for={community <- @communities}>
          <.link
            navigate={Routes.curation_frontend_path(@socket, :community, community)}
            class="text-link hover:text-link-dark"
          >
            {community.title}
          </.link>
        </li>
      </ul>

      <p :if={@communities == []}>You are not curating or moderating any community.</p>
    </div>
    """
  end
end
