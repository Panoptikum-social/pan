defmodule PanWeb.Live.Curation.Community do
  use PanWeb, :live_view
  on_mount PanWeb.Live.AssignUserAndAdmin
  alias PanWeb.{Community, Curation}
  alias PanWeb.Component.CurationGrade
  alias PanWeb.Router.Helpers, as: Routes

  def mount(%{"id" => id}, _session, socket) do
    community = Community.get_by_id(id)
    permissions = Curation.permissions(socket.assigns.current_user_id, community.id)

    if permissions.read do
      {:ok,
       socket
       |> assign(community: community, permissions: permissions, filter: :open, search: "")
       |> fetch()}
    else
      {:ok,
       socket
       |> put_flash(:error, "You are not a curator of this community.")
       |> redirect(to: Routes.curation_frontend_path(socket, :index))}
    end
  end

  defp fetch(%{assigns: assigns} = socket) do
    podcasts =
      Curation.overview(
        assigns.community,
        assigns.current_user_id,
        assigns.filter,
        assigns.search
      )

    assign(socket, podcasts: podcasts)
  end

  # Only moderators and admins get to see podcasts that are done.
  def handle_event("filter", %{"search" => search} = params, socket) do
    filter =
      if socket.assigns.permissions.manage,
        do: Map.get(%{"done" => :done, "all" => :all}, params["filter"], :open),
        else: :open

    {:noreply, socket |> assign(search: search, filter: filter) |> fetch()}
  end

  def handle_event("toggle_open", %{"podcast_id" => podcast_id, "open" => open}, socket) do
    if socket.assigns.permissions.manage do
      Curation.set_open(socket.assigns.community, String.to_integer(podcast_id), open == "true")
    end

    {:noreply, fetch(socket)}
  end

  def render(assigns) do
    ~H"""
    <div class="m-4">
      <h1 class="text-3xl">Curations in {@community.title}</h1>

      <form id="curation-filter" phx-change="filter" phx-submit="filter" class="my-4 flex gap-4">
        <input
          type="text"
          name="search"
          value={@search}
          phx-debounce="300"
          autocomplete="off"
          placeholder="Podcast title"
          class="input input-bordered input-sm w-full max-w-md"
        />
        <select :if={@permissions.manage} name="filter" class="select select-bordered select-sm">
          <option value="open" selected={@filter == :open}>open for curation</option>
          <option value="done" selected={@filter == :done}>done</option>
          <option value="all" selected={@filter == :all}>all</option>
        </select>
      </form>

      <table class="table table-sm">
        <thead>
          <tr>
            <th>Podcast</th>
            <th>Grades</th>
            <th>Curated by me</th>
            <th :if={@permissions.manage}>Open for curation</th>
          </tr>
        </thead>
        <tbody>
          <tr :for={podcast <- @podcasts}>
            <td>
              <.link
                navigate={Routes.curation_frontend_path(@socket, :podcast, @community, podcast.id)}
                class="text-link hover:text-link-dark"
              >
                {podcast.title}
              </.link>
            </td>
            <td class="flex flex-wrap gap-1">
              <CurationGrade.badge
                :for={grade <- Curation.grades()}
                :if={podcast.grades[to_string(grade)]}
                grade={grade}
                count={podcast.grades[to_string(grade)]}
              />
            </td>
            <td>{if podcast.mine, do: "✓"}</td>
            <td :if={@permissions.manage}>
              <button
                phx-click="toggle_open"
                phx-value-podcast_id={podcast.id}
                phx-value-open={to_string(!podcast.open)}
                class={["btn btn-xs", if(podcast.open, do: "btn-success", else: "btn-outline")]}
              >
                {if podcast.open, do: "open – mark done", else: "done – reopen"}
              </button>
            </td>
          </tr>
        </tbody>
      </table>

      <p :if={@podcasts == []} class="my-4">No podcasts.</p>
    </div>
    """
  end
end
