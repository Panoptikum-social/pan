defmodule PanWeb.Live.Admin.Opml.Index do
  use Surface.LiveView,
    layout: {PanWeb.LayoutView, "live_admin.html"},
    container: {:div, class: "m-4"}

  on_mount {PanWeb.Live.Auth, :admin}

  alias PanWeb.{Opml, Endpoint}
  alias PanWeb.Surface.LinkButton
  alias PanWeb.Surface.Admin.{SortLink, Pagination}
  import PanWeb.Router.Helpers

  def mount(_params, _session, socket) do
    socket = assign(socket, sort_by: :inserted_at, sort_order: :desc, page: 1, per_page: 10, filter_by: nil)

    {:ok, socket |> fetch() |> paginate()}
  end

  defp fetch(%{assigns: %{sort_by: sort_by, sort_order: sort_order}} = socket) do
    opmls =
      Opml.all_with_user(sort_by, sort_order)
      |> Enum.map(&Map.put_new(&1, :user_name, &1.user.name))

    assign(socket,
      opmls: opmls,
      nr_of_unfiltered: Enum.count(opmls),
      nr_of_filtered: Enum.count(opmls)
    )
  end

  defp paginate(%{assigns: %{page: page, per_page: per_page, opmls: opmls}} = socket) do
    assign(socket, filtered_opmls: Enum.slice(opmls, (page - 1) * per_page, per_page))
  end

  defp sort(%{assigns: %{sort_by: sort_by, sort_order: sort_order, opmls: opmls}} = socket) do
    sorted_opmls = Enum.sort_by(opmls, &Map.get(&1, sort_by), sort_order)
    assign(socket, opmls: sorted_opmls)
  end

  defp filter(%{assigns: %{filter_by: filter_by, opmls: opmls}} = socket) do
    filtered_opmls = Enum.filter(opmls, &opml_contains?(&1, filter_by))
    assign(socket, opmls: filtered_opmls, nr_of_filtered: Enum.count(filtered_opmls))
  end

  defp opml_contains?(opml, value) do
    Enum.any?(Map.values(opml), &String.contains?(&1 |> inspect(), value))
  end

  def handle_event("paginate", %{"page" => page}, socket) do
    {:noreply, assign(socket, page: String.to_integer(page)) |> paginate()}
  end

  def handle_event("sort", %{"sort-by" => sort_by, "sort-order" => sort_order}, socket) do
    {:noreply,
     assign(socket, sort_by: String.to_atom(sort_by), sort_order: String.to_atom(sort_order))
     |> sort()
     |> paginate()}
  end

  def handle_event("filter", %{"value" => value}, socket) do
    {:noreply,
     assign(socket, page: 1, filter_by: value)
     |> fetch()
     |> filter()
     |> sort()
     |> paginate()}
  end

  def render(assigns) do
    ~F"""
    <div class="flex justify-between max-w-7xl">
      <h2 class="text-2xl">Listing opmls</h2>
      <input type="text"  placeholder="Filter" phx-keyup="filter" value={@filter_by} />
    </div>

    <table cellpadding="4" class="my-4">
      <thead>
        <tr>
          <th class="border border-gray-light">
            <SortLink field={:id} click="sort" {=@sort_order} {=@sort_by}>Id</SortLink>
          </th>
          <th class="border border-gray-light">
            <SortLink field={:user_name} click="sort" {=@sort_order} {=@sort_by}>User</SortLink></th>
          <th class="border border-gray-light">
            <SortLink field={:content_type} click="sort" {=@sort_order} {=@sort_by}>Content Type</SortLink>
          </th>
          <th class="border border-gray-light">
            <SortLink field={:filename} click="sort" {=@sort_order} {=@sort_by}>Filename</SortLink>
          </th>
          <th class="border border-gray-light">
            <SortLink field={:inserted_at} click="sort" {=@sort_order} {=@sort_by}>inserted at</SortLink>
          </th>
          <th class="border border-gray-light">
            <SortLink field={:path} click="sort" {=@sort_order} {=@sort_by}>Path</SortLink>
          </th>
          <th class="border border-gray-light">Actions</th>
        </tr>
      </thead>
      <tbody>
        {#for opml <- @filtered_opmls}
          <tr class="odd:bg-white">
            <td class="border border-gray-light">{opml.id}</td>
            <td class="border border-gray-light">{opml.user_name}</td>
            <td class="border border-gray-light">{opml.content_type}</td>
            <td class="border border-gray-light">{opml.filename}</td>
            <td class="border border-gray-light"><nobr> {opml.inserted_at |> Timex.format!("{YYYY}-{0M}-{0D} {h24}:{m}:{s}")}</nobr></td>
            <td class="border border-gray-light">{opml.path}</td>
            <td class="border border-gray-light">
              <LinkButton title="Parse"
                          to={opml_path(Endpoint, :import, opml.id)}
                          class="text-sm border-primary-dark bg-primary hover:bg-primary-light text-white" />
              <LinkButton title="Show"
                          class="text-sm border-gray bg-white hover:bg-gray-light"
                          to={opml_path(Endpoint, :show, opml.id)} />
              <LinkButton title="Edit"
                          class="text-sm border-warning-dark bg-warning hover:bg-warning-light text-white"
                          to={opml_path(Endpoint, :edit, opml.id)} />
              <LinkButton title="Delete"
                          to={opml_path(Endpoint, :delete, opml.id)}
                          method={:delete}
                          class="text-sm border-danger-dark bg-danger hover:bg-danger-light text-white"
                          opts={[confirm: "Are you sure?"]} />
            </td>
          </tr>
        {/for}
      </tbody>
    </table>

    <Pagination nr_of_pages={Float.ceil(@nr_of_filtered / @per_page) |> round}
                {=@nr_of_unfiltered} {=@nr_of_filtered} {=@page} {=@per_page}
                click="paginate" class="mb-4 max-w-3xl" />

    <LinkButton title="New opml"
                to={opml_path(Endpoint, :new)} />
    """
  end
end
