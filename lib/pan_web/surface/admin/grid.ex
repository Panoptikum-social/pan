defmodule PanWeb.Surface.Admin.Grid do
  use Surface.LiveComponent
  import Ecto.Query
  alias PanWeb.Surface.Admin.Naming
  alias Pan.Repo
  alias PanWeb.Surface.Admin.{SortLink, Pagination, GridPresenter, PerPageLink}
  alias Surface.Components.{Form, Link, LiveRedirect, Form.TextInput}
  require Integer

  prop(heading, :string, required: false, default: "Records")
  prop(model, :module, required: true)
  prop(path_helper, :atom, required: false)
  prop(cols, :list, required: false, default: [])
  prop(search_filter, :tuple, default: {})
  prop(per_page, :integer, default: 20)
  prop(navigation, :boolean, required: false, default: true)
  prop(class, :css_class, required: false)

  data(search_options, :map, default: %{})
  data(page, :integer, default: 1)
  data(like_search, :boolean, default: false)
  prop(hide_filtered, :boolean, default: true)
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
      |> assign(search_filter: assigns.search_filter)
      |> get_records

    {:ok, socket}
  end

  def handle_event("per_page", %{"delta" => delta}, socket) do
    socket =
      assign(socket, per_page: socket.assigns.per_page + String.to_integer(delta))
      |> get_records

    {:noreply, socket}
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
      |> get_records

    {:noreply, socket}
  end

  def handle_event("sort", %{"sort-by" => sort_by, "sort-order" => sort_order}, socket) do
    socket =
      socket
      |> assign(
        sort_by: String.to_atom(sort_by),
        sort_order: String.to_atom(sort_order)
      )
      |> get_records

    {:noreply, socket}
  end

  def handle_event("paginate", %{"page" => page, "per-page" => per_page}, socket) do
    socket =
      socket
      |> assign(
        page: String.to_integer(page),
        per_page: String.to_integer(per_page)
      )
      |> get_records

    {:noreply, socket}
  end

  def handle_event("toggle_search_mode", _, socket) do
    socket =
      socket
      |> assign(like_search: !socket.assigns.like_search)
      |> get_records

    {:noreply, socket}
  end

  def handle_event("toggle_hide_filtered", _, socket) do
    socket =
      socket
      |> assign(hide_filtered: !socket.assigns.hide_filtered)
      |> get_records

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
          Naming.path(%{socket: socket, model: model, method: :index, path_helper: path_helper})

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
      search_filter: a.search_filter,
      like_search: a.like_search,
      hide_filtered: a.hide_filtered,
    ]

    assign(socket, records: load(a.model, criteria, a.columns))
  end

  defp load(model, criteria, columns) when is_list(criteria) do
    from(r in model)
    |> apply_criteria(criteria)
    |> select_columns(columns)
    |> Repo.all
  end

  defp apply_criteria(query, criteria) do
    Enum.reduce(criteria, query, &apply_criterium(&1, &2, criteria[:like_search], criteria[:hide_filtered]))
  end

  defp apply_criterium({:paginate, %{page: page, per_page: per_page}}, query, _, _) do
    from(q in query, offset: ^((page - 1) * per_page), limit: ^per_page)
  end

  defp apply_criterium({:sort, %{sort_by: sort_by, sort_order: sort_order}}, query, _, _) do
    from(q in query, order_by: [{^sort_order, ^sort_by}])
  end

  defp apply_criterium({:search_filter, {_, _}}, query, _, false = _hide_filtered), do: query

  defp apply_criterium({:search_filter, {column, values}}, query, _, true = _hide_filtered)
       when is_list(values) do
    from(q in query, where: field(q, ^column) in ^values)
  end

  defp apply_criterium({:search_filter, {column, value}}, query, _, true = _hide_filtered)
       when is_integer(value) do
    from(q in query, where: field(q, ^column) == ^value)
  end

  defp apply_criterium({:search, search_options}, query, like_search, hide_filtered) do
    Enum.reduce(search_options, query, &apply_search_option(&1, &2, like_search, hide_filtered))
  end

  defp apply_criterium({:search_filter, {}}, query, _, _), do: query

  # consumed by :search, no need to restrict anything here
  defp apply_criterium({:like_search, _}, query, _, _), do: query
  defp apply_criterium({:hide_filtered, _}, query, _, _), do: query

  defp apply_search_option({_column, ""}, query, _, _), do: query

  defp apply_search_option({column, value}, query, true = _, _) do
    from(q in query,
      where: ilike(fragment("cast (? as text)", field(q, ^column)), ^("%" <> value <> "%"))
    )
  end

  defp apply_search_option({column, value}, query, false = _, _) do
    from(q in query, where: ^[{column, value}])
  end

  defp select_columns(query, columns) do
    column_atoms = Enum.map(columns, & &1.field)
    from(q in query, select: ^column_atoms)
  end

  defp width(type) do
    case type do
      :id -> "6rem"
      :integer -> "4rem"
      :date -> "6rem"
      :datetime -> "12rem"
      :naive_datetime -> "12rem"
      :string -> "16rem"
      Ecto.EctoText -> "16rem"
      :boolean -> "4rem"
    end
  end

  defp to_be_dyed?(record, assigns) do
    if assigns.search_filter != {} do
      {column, value} = assigns.search_filter
      !assigns.hide_filtered && Map.get(record, column) == value
    else
      false
    end
  end
end
