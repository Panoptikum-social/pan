defmodule PanWeb.Live.Admin.Podcast.Owners do
  use PanWeb, :admin_live_view
  alias PanWeb.{Podcast, User}
  import PanWeb.Router.Helpers

  @limit 25

  def mount(_params, _session, socket) do
    {:ok, assign(socket, search: "") |> fetch()}
  end

  defp fetch(%{assigns: %{search: search}} = socket) do
    assign(socket, podcasts: Podcast.owner_admin_list(String.trim(search), @limit))
  end

  def handle_event("search", %{"search" => search}, socket) do
    {:noreply, assign(socket, search: search) |> fetch()}
  end

  def handle_event("assign", %{"podcast_id" => podcast_id, "user" => identifier}, socket) do
    case User.find_by_identifier(identifier) do
      nil ->
        {:noreply, put_flash(socket, :error, "No user found for \"#{identifier}\".")}

      user ->
        Podcast.set_owner(String.to_integer(podcast_id), user.id, socket.assigns.current_user_id)

        {:noreply,
         socket
         |> put_flash(:info, "Podcast #{podcast_id} assigned to #{user.username}.")
         |> fetch()}
    end
  end

  def handle_event("unassign", %{"podcast_id" => podcast_id}, socket) do
    Podcast.set_owner(String.to_integer(podcast_id), nil, socket.assigns.current_user_id)

    {:noreply,
     socket
     |> put_flash(:info, "Podcast #{podcast_id} unassigned.")
     |> fetch()}
  end

  def render(assigns) do
    ~H"""
    <div class="m-4">
      <h1 class="text-3xl">Podcast owners</h1>

      <p class="my-2">
        Without a search, the podcasts that have an owner are listed. Search by podcast id, title
        or the owner's username or email. Assign to a user by id, username or email; every change
        is journaled.
      </p>

      <form id="owners-search" phx-change="search" phx-submit="search" class="my-4">
        <input
          type="text"
          name="search"
          value={@search}
          phx-debounce="300"
          autocomplete="off"
          placeholder="Podcast id, title, owner username or email"
          class="input input-bordered input-sm w-full max-w-md"
        />
      </form>

      <table class="table table-sm">
        <thead>
          <tr>
            <th>Podcast</th>
            <th>Owner in feed</th>
            <th>Assigned to</th>
            <th>Assign to</th>
          </tr>
        </thead>
        <tbody>
          <tr :for={podcast <- @podcasts}>
            <td>
              <.link href={podcast_frontend_path(PanWeb.Endpoint, :show, podcast)} class="link">
                {podcast.title}
              </.link>
              <span class="text-xs text-gray-dark">#{podcast.id}</span>
            </td>
            <td class="text-sm">{Enum.join(podcast.feed_owner_emails, ", ")}</td>
            <td>
              <span :if={podcast.owner}>{podcast.owner.username} ({podcast.owner.email})</span>
              <button
                :if={podcast.owner}
                phx-click="unassign"
                phx-value-podcast_id={podcast.id}
                data-confirm={"Unassign #{podcast.title}?"}
                class="btn btn-warning btn-xs ml-2"
              >
                Unassign
              </button>
            </td>
            <td>
              <form phx-submit="assign" class="flex gap-2">
                <input type="hidden" name="podcast_id" value={podcast.id} />
                <input
                  type="text"
                  name="user"
                  placeholder="id, username or email"
                  class="input input-bordered input-xs"
                />
                <button class="btn btn-primary btn-xs">
                  {if podcast.owner, do: "Reassign", else: "Assign"}
                </button>
              </form>
            </td>
          </tr>
        </tbody>
      </table>

      <p :if={@podcasts == []} class="my-4">Nothing found.</p>
    </div>
    """
  end
end
