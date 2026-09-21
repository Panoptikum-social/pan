defmodule PanWeb.Live.Admin.User.Retention do
  use PanWeb, :admin_live_view
  alias PanWeb.{User, Endpoint}
  alias PanWeb.Admin.SortLink
  alias PanWeb.Component.LinkButton
  import PanWeb.Router.Helpers

  @per_page 50
  @sortable [
    :id,
    :username,
    :email,
    :email_verified,
    :inserted_at,
    :last_login_at,
    :marked_for_deletion_at
  ]
  @sort_orders [
    :asc,
    :desc,
    :asc_nulls_last,
    :asc_nulls_first,
    :desc_nulls_last,
    :desc_nulls_first
  ]

  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       filter: :all,
       sort_by: :inserted_at,
       sort_order: :desc,
       page: 1,
       selected: MapSet.new()
     )
     |> fetch()}
  end

  defp fetch(%{assigns: assigns} = socket) do
    count = User.count_retention_users(assigns.filter)
    pages = max(ceil(count / @per_page), 1)
    page = min(assigns.page, pages)

    assign(socket,
      page: page,
      pages: pages,
      counts: Map.new(User.retention_filters(), &{&1, User.count_retention_users(&1)}),
      users:
        User.retention_users(
          assigns.filter,
          assigns.sort_by,
          assigns.sort_order,
          @per_page,
          (page - 1) * @per_page
        )
    )
  end

  def handle_event("filter", %{"filter" => filter}, socket) do
    case Enum.find(User.retention_filters(), &(Atom.to_string(&1) == filter)) do
      nil ->
        {:noreply, socket}

      filter ->
        {:noreply, assign(socket, filter: filter, page: 1, selected: MapSet.new()) |> fetch()}
    end
  end

  def handle_event("sort", %{"sort-by" => sort_by, "sort-order" => sort_order}, socket) do
    sort_by = Enum.find(@sortable, &(Atom.to_string(&1) == sort_by))
    sort_order = Enum.find(@sort_orders, &(Atom.to_string(&1) == sort_order))

    if sort_by && sort_order do
      {:noreply, assign(socket, sort_by: sort_by, sort_order: sort_order) |> fetch()}
    else
      {:noreply, socket}
    end
  end

  def handle_event("page", %{"delta" => delta}, socket) do
    page = max(socket.assigns.page + String.to_integer(delta), 1)
    {:noreply, assign(socket, page: page, selected: MapSet.new()) |> fetch()}
  end

  def handle_event("toggle", %{"id" => id}, %{assigns: %{selected: selected}} = socket) do
    id = String.to_integer(id)

    selected =
      if MapSet.member?(selected, id),
        do: MapSet.delete(selected, id),
        else: MapSet.put(selected, id)

    {:noreply, assign(socket, selected: selected)}
  end

  def handle_event("select_all", _, %{assigns: %{users: users, selected: selected}} = socket) do
    ids = MapSet.new(users, & &1.id)

    selected =
      if MapSet.subset?(ids, selected),
        do: MapSet.difference(selected, ids),
        else: MapSet.union(selected, ids)

    {:noreply, assign(socket, selected: selected)}
  end

  def handle_event("mark", _, socket) do
    count = socket.assigns.selected |> MapSet.to_list() |> User.mark_for_deletion()
    {:noreply, done(socket, "Marked #{count} users for deletion.")}
  end

  def handle_event("unmark", _, socket) do
    count = socket.assigns.selected |> MapSet.to_list() |> User.unmark_for_deletion()
    {:noreply, done(socket, "Removed the deletion mark from #{count} users.")}
  end

  def handle_event("delete", _, socket) do
    count = socket.assigns.selected |> MapSet.to_list() |> User.delete_deletable()
    {:noreply, done(socket, "Deleted #{count} users.")}
  end

  defp done(socket, message) do
    socket
    |> assign(selected: MapSet.new())
    |> fetch()
    |> put_flash(:info, message)
  end

  defp format_date(nil), do: "–"
  defp format_date(naive_date_time), do: Calendar.strftime(naive_date_time, "%Y-%m-%d")

  defp filter_title(:all), do: "All"
  defp filter_title(:unverified), do: "Unverified"
  defp filter_title(:never_logged_in), do: "Never logged in"
  defp filter_title(:inactive), do: "Inactive for 2 years"
  defp filter_title(:marked), do: "Marked"
  defp filter_title(:deletable), do: "Deletable (marked > #{User.deletion_grace_days()} days)"

  def render(assigns) do
    ~H"""
    <div class="m-4">
      <h1 class="text-3xl">User retention</h1>

      <p class="my-2">
        Admins and moderators are not listed. Deleting works only for users that have been marked
        for at least {User.deletion_grace_days()} days.
      </p>

      <div role="tablist" class="tabs tabs-boxed w-fit my-4">
        <a
          :for={filter <- User.retention_filters()}
          role="tab"
          href="#"
          phx-click="filter"
          phx-value-filter={filter}
          class={["tab", filter == @filter && "tab-active"]}
        >
          {filter_title(filter)} ({@counts[filter]})
        </a>
      </div>

      <div class="flex flex-wrap gap-4 items-center my-2">
        <span>{MapSet.size(@selected)} selected</span>
        <button
          :if={@filter not in [:marked, :deletable]}
          phx-click="mark"
          disabled={MapSet.size(@selected) == 0}
          class="btn btn-warning btn-sm"
        >
          Mark for deletion
        </button>
        <button
          :if={@filter in [:marked, :deletable]}
          phx-click="unmark"
          disabled={MapSet.size(@selected) == 0}
          class="btn btn-outline btn-sm"
        >
          Remove mark
        </button>
        <button
          :if={@filter == :deletable}
          phx-click="delete"
          disabled={MapSet.size(@selected) == 0}
          data-confirm="Delete the selected users and their data for good?"
          class="btn btn-error btn-sm"
        >
          Delete selected
        </button>
      </div>

      <table class="table table-zebra table-xs my-4 w-auto">
        <thead>
          <tr>
            <th>
              <input
                type="checkbox"
                class="checkbox checkbox-xs"
                phx-click="select_all"
                checked={@users != [] and Enum.all?(@users, &MapSet.member?(@selected, &1.id))}
              />
            </th>
            <th :for={
              {field, title} <- [
                id: "ID",
                username: "Username",
                email: "Email",
                email_verified: "Verified",
                inserted_at: "Signed up",
                last_login_at: "Last login",
                marked_for_deletion_at: "Marked"
              ]
            }>
              <SortLink.render field={field} click="sort" sort_order={@sort_order} sort_by={@sort_by}>
                {title}
              </SortLink.render>
            </th>
          </tr>
        </thead>
        <tbody>
          <tr :for={user <- @users}>
            <td>
              <input
                type="checkbox"
                class="checkbox checkbox-xs"
                phx-click="toggle"
                phx-value-id={user.id}
                checked={MapSet.member?(@selected, user.id)}
              />
            </td>
            <td class="text-right">
              <LinkButton.render
                title={user.id}
                to={databrowser_path(Endpoint, :show, "user", user.id)}
                class="btn-primary"
              />
            </td>
            <td>{user.username}</td>
            <td>{user.email}</td>
            <td>{if user.email_verified, do: "yes", else: "no"}</td>
            <td class="whitespace-nowrap">{format_date(user.inserted_at)}</td>
            <td class="whitespace-nowrap">{format_date(user.last_login_at)}</td>
            <td class="whitespace-nowrap">{format_date(user.marked_for_deletion_at)}</td>
          </tr>
        </tbody>
      </table>

      <div class="flex gap-4 items-center">
        <button phx-click="page" phx-value-delta="-1" disabled={@page <= 1} class="btn btn-sm">
          Previous
        </button>
        <span>Page {@page} of {@pages}</span>
        <button phx-click="page" phx-value-delta="1" disabled={@page >= @pages} class="btn btn-sm">
          Next
        </button>
      </div>
    </div>
    """
  end
end
