defmodule PanWeb.Surface.Admin.Grid do
  use Surface.LiveComponent
  import Ecto.Query
  alias PanWeb.Router.Helpers, as: Routes
  alias Pan.Repo
  alias PanWeb.Surface.Admin.{SortLink, Pagination, GridPresenter}
  alias PanWeb.Surface.Icon
  alias Surface.Components.{Form, Link, LiveRedirect, Form.TextInput}
  require Integer

  prop(heading, :string, required: false, default: "Records")
  prop(resource, :module, required: true)
  prop(path_helper, :atom, required: true)

  data(page, :integer, default: 1)
  data(per_page, :integer, default: 20)
  data(search_options, :map, default: %{})
  data(like_search, :boolean, default: false)
  data(sort_by, :atom, default: :id)
  data(sort_order, :atom, default: :asc)
  data(records, :list, default: [])
  slot(columns)

  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> get_records()

    {:ok, socket}
  end

  def handle_event("search", %{"search" => search}, socket) do
    [column_string | _] = Map.keys(search)
    column = String.to_atom(column_string)
    search_options = Map.merge(socket.assigns.search_options, %{column => search[column_string]})

    socket =
      socket
      |> assign(
        search_options: search_options,
        column: search[column_string]
      )
      |> get_records()

    {:noreply, socket}
  end

  def handle_event("sort", %{"sort-by" => sort_by, "sort-order" => sort_order}, socket) do
    socket =
      socket
      |> assign(
        sort_by: String.to_atom(sort_by),
        sort_order: String.to_atom(sort_order)
      )
      |> get_records()

    {:noreply, socket}
  end

  def handle_event("paginate", %{"page" => page, "per-page" => per_page}, socket) do
    socket =
      socket
      |> assign(
        page: String.to_integer(page),
        per_page: String.to_integer(per_page)
      )
      |> get_records()

    {:noreply, socket}
  end

  def handle_event("toggle_search_mode", _, socket) do
    socket =
      socket
      |> assign(like_search: !socket.assigns.like_search)
      |> get_records()

    {:noreply, socket}
  end

  defp get_records(socket) do
    a = socket.assigns

    criteria = [
      paginate: %{page: a.page, per_page: a.per_page},
      sort: %{sort_by: a.sort_by, sort_order: a.sort_order},
      search: a.search_options,
      like_search: a.like_search
    ]

    assign(socket, records: load(a.resource, criteria, a.columns))
  end

  defp load(resource, criteria, columns) when is_list(criteria) do
    from(r in resource)
    |> apply_criteria(criteria)
    |> select_columns(columns)
    |> Repo.all()
  end

  defp apply_criteria(query, criteria) do
    Enum.reduce(criteria, query, fn
      {:paginate, %{page: page, per_page: per_page}}, query ->
        from(q in query,
          offset: ^((page - 1) * per_page),
          limit: ^per_page
        )

      {:sort, %{sort_by: sort_by, sort_order: sort_order}}, query ->
        from(q in query, order_by: [{^sort_order, ^sort_by}])

      {:search, search_options}, query ->
        Enum.reduce(search_options, query, fn
          {column, value}, query ->
            if value != "" do
              if criteria[:like_search] do
                from(q in query,
                  where:
                    ilike(fragment("cast (? as text)", field(q, ^column)), ^("%" <> value <> "%"))
                )
              else
                from(q in query, where: ^[{column, value}])
              end
            else
              query
            end
        end)

      # consumed by :search, no need to restrict anything here
      {:like_search, _}, query ->
        query
    end)
  end

  defp select_columns(query, columns) do
    column_atoms = Enum.map(columns, &String.to_atom(&1.field))
    from(q in query, select: ^column_atoms)
  end

  defp width(type) do
    case type do
      :integer -> "w-16"
      :datetime -> "w-48"
      :string -> "w-128"
      :boolean -> "w-16"
    end
  end
end

defmodule Column do
  use Surface.Component, slot: "columns"

  prop(field, :string)
  prop(label, :string)
  prop(sortable, :boolean, default: true)
  prop(searchable, :boolean, default: true)
  prop(presenter, :fun)
  prop(type, :atom, values: [:string, :integer, :datetime], default: :string)
end
