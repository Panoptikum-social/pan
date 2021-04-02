defmodule PanWeb.Surface.Admin.Grid do
  use Surface.LiveComponent
  import Ecto.Query
  alias PanWeb.Surface.Admin.Naming
  alias Pan.Repo
  alias PanWeb.Surface.Admin.{SortLink, Pagination, GridPresenter}
  alias Surface.Components.{Form, Link, LiveRedirect, Form.TextInput}
  require Integer

  prop(heading, :string, required: false, default: "Records")
  prop(model, :module, required: true)
  prop(path_helper, :atom, required: false)
  prop(cols, :list, required: false, default: [])

  data(page, :integer, default: 1)
  data(per_page, :integer, default: 25)
  data(search_options, :map, default: %{})
  data(like_search, :boolean, default: false)
  data(sort_by, :atom, default: :id)
  data(sort_order, :atom, default: :asc)
  data(records, :list, default: [])
  data(columns, :list, default: [])
  slot(slot_columns)

  def update(assigns, socket) do
    columns = if assigns.cols == [], do: assigns.slot_columns, else: assigns.cols

    socket =
      assign(socket, assigns)
      |> assign(columns: columns)
      |> assign(sort_by: List.first(columns)[:field])
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

  def handle_event("delete", %{"id" => id_string}, socket) do
    id = String.to_integer(id_string)
    model = socket.assigns.model
    record = Repo.get!(model, id)
    path_helper = socket.assigns.path_helper

    try do
      Repo.delete(record)
      if Map.has_key?(record, :elastic), do: model.delete_search_index(id)
      {:noreply, get_records(socket)}
    rescue
      e in Postgrex.Error ->
        %Postgrex.Error{postgres: %{message: message}} = e
        index_path =
          Naming.path(%{socket: socket,
                        model: model,
                        method: :index,
                        path_helper: path_helper})
        socket =
          put_flash(socket, :error, message)
          |> redirect(to: index_path)
        {:noreply, socket}
    end
  end

  defp get_records(socket) do
    a = socket.assigns

    criteria = [
      paginate: %{page: a.page, per_page: a.per_page},
      sort: %{sort_by: a.sort_by, sort_order: a.sort_order},
      search: a.search_options,
      like_search: a.like_search
    ]

    assign(socket, records: load(a.model, criteria, a.columns))
  end

  defp load(model, criteria, columns) when is_list(criteria) do
    from(r in model)
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
    column_atoms = Enum.map(columns, & &1.field)
    from(q in query, select: ^column_atoms)
  end

  defp width(type) do
    case type do
      :id -> "w-16"
      :integer -> "w-16"
      :date -> "w-24"
      :datetime -> "w-48"
      :naive_datetime -> "w-48"
      :string -> "w-128"
      Ecto.EctoText -> "w-128"
      :boolean -> "w-16"
    end
  end
end
