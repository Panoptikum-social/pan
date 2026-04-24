defmodule PanWeb.Live.Admin.Opml.Index do
  use PanWeb, :admin_live_view

  alias PanWeb.{Opml, Endpoint}
  alias PanWeb.Component.LinkButton
  alias PanWeb.Admin.SortLink
  alias PanWeb.Admin.Pagination
  import PanWeb.Router.Helpers

  def mount(_params, _session, socket) do
    socket =
      assign(socket,
        sort_by: :inserted_at,
        sort_order: :desc,
        page: 1,
        per_page: 10,
        filter_by: nil
      )

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
    ~H"""
    <div class="m-4">
      <div class="flex justify-between max-w-7xl">
        <h1 class="text-3xl">Listing opmls</h1>
        <input type="text" placeholder="Filter" phx-keyup="filter" value={@filter_by} class="input" />
      </div>

      <table class="table table-zebra table-xs my-4 w-auto">
        <thead>
          <tr>
            <th><SortLink.render field={:id} click="sort" sort_order={@sort_order} sort_by={@sort_by}>Id</SortLink.render></th>
            <th><SortLink.render field={:user_name} click="sort" sort_order={@sort_order} sort_by={@sort_by}>User</SortLink.render></th>
            <th><SortLink.render field={:content_type} click="sort" sort_order={@sort_order} sort_by={@sort_by}>Content Type</SortLink.render></th>
            <th><SortLink.render field={:filename} click="sort" sort_order={@sort_order} sort_by={@sort_by}>Filename</SortLink.render></th>
            <th><SortLink.render field={:inserted_at} click="sort" sort_order={@sort_order} sort_by={@sort_by}>inserted at</SortLink.render></th>
            <th><SortLink.render field={:path} click="sort" sort_order={@sort_order} sort_by={@sort_by}>Path</SortLink.render></th>
            <th>Actions</th>
          </tr>
        </thead>
        <tbody>
          <tr :for={opml <- @filtered_opmls}>
            <td>{opml.id}</td>
            <td>{opml.user_name}</td>
            <td>{opml.content_type}</td>
            <td>{opml.filename}</td>
            <td><nobr>{Calendar.strftime(opml.inserted_at, "%c")}</nobr></td>
            <td>{opml.path}</td>
            <td>
              <LinkButton.render title="Parse"
                          to={opml_path(Endpoint, :import, opml.id)}
                          class="btn-primary" />
              <LinkButton.render title="Show"
                          class="btn-ghost"
                          to={opml_path(Endpoint, :show, opml.id)} />
              <LinkButton.render title="Edit"
                          class="btn-warning"
                          to={opml_path(Endpoint, :edit, opml.id)} />
              <LinkButton.render title="Delete"
                          to={opml_path(Endpoint, :delete, opml.id)}
                          method={:delete}
                          class="text-sm border-danger-dark bg-danger hover:bg-danger-light text-white"
                          opts={[confirm: "Are you sure?"]} />
            </td>
          </tr>
        </tbody>
      </table>

      <Pagination.render nr_of_pages={Float.ceil(@nr_of_filtered / @per_page) |> round}
                  nr_of_unfiltered={@nr_of_unfiltered}
                  nr_of_filtered={@nr_of_filtered}
                  page={@page}
                  per_page={@per_page}
                  click="paginate"
                  class="mb-4 max-w-3xl" />

      <LinkButton.render title="New opml" to={opml_path(Endpoint, :new)} />
    </div>
    """
  end
end
