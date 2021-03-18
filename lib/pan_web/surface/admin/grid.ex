defmodule PanWeb.Surface.Admin.Grid do
  use Surface.LiveComponent
  import Ecto.Query
  alias PanWeb.Router.Helpers, as: Routes
  alias Pan.Repo
  alias PanWeb.Surface.Admin.{SortLink, Pagination}
  alias PanWeb.Surface.Icon
  alias Surface.Components.{Form, Link, Form.TextInput}

  prop heading, :string, required: false, default: "Records"
  prop current_page, :integer, required: false, default: 1
  prop per_page, :integer, required: false, default: 10
  prop sort_by, :atom, required: false, default: :id
  prop sort_order, :atom, required: false, default: :asc
  prop resource, :module, required: true
  prop path_helper, :atom, required: true
  prop records_getter_params, :map, required: false, default: %{}
  prop search_options, :map, required: false, default: %{}
  prop like_search, :boolean, required: false, default: false

  data records, :list, default: []
  slot columns

  def update(assigns, socket) do
    socket = socket
    |> assign(assigns)
    |> get_records()
    {:ok, socket}
  end

  def handle_event("search", %{"search" => search}, socket) do
    [column_string | _] = Map.keys(search)
    column = String.to_atom(column_string)
    search_options = Map.merge(socket.assigns.search_options, %{column => search[column_string]})
    socket = socket
      |> assign(search_options: search_options, column: search[column_string])
      |> get_records()

    {:noreply, socket}
  end

  def handle_event("sort", %{"sort-by"=> sort_by, "sort-order"=> sort_order}, socket) do
    socket = socket
      |> assign(sort_by: String.to_atom(sort_by), sort_order: String.to_atom(sort_order))
      |> get_records()
    {:noreply, socket}
  end

  def handle_event("paginate", %{"page" => page, "per-page" => per_page}, socket) do
    socket = socket
      |> assign(current_page: String.to_integer(page), per_page: String.to_integer(per_page))
      |> get_records()
    {:noreply, socket}
  end

  def handle_event("toggle_search_mode", _, socket) do
    socket = socket
      |> assign(like_search: !socket.assigns.like_search)
      |> get_records()
    {:noreply, socket}
  end

  defp get_records(socket) do
    records =
      load(socket.assigns.resource,
        paginate: %{
          page: socket.assigns.current_page,
          per_page: socket.assigns.per_page},
        sort: %{
          sort_by: socket.assigns.sort_by,
          sort_order: socket.assigns.sort_order },
        search: socket.assigns.search_options,
        like_search: socket.assigns.like_search,
        additional_params: socket.assigns[:records_getter_params]
      )

    assign(socket, records: records)
  end

  defp load(resource, criteria) when is_list(criteria) do
    query = from r in resource

    Enum.reduce(criteria, query, fn
      {:paginate, %{page: page, per_page: per_page}}, query ->
        from q in query,
          offset: ^((page - 1) * per_page),
          limit: ^per_page

      {:sort, %{sort_by: sort_by, sort_order: sort_order}}, query ->
        from q in query, order_by: [{^sort_order, ^sort_by}]

      {:additional_params, _}, query -> query

      {:search, search_options}, query ->
        Enum.reduce(search_options, query, fn
          {column, value}, query ->
            if value != "" do
              if criteria[:like_search] do
                from q in query, where: ilike(fragment("cast (? as text)", field(q, ^column)), ^("%"<>value<>"%"))
              else
                from q in query, where: ^[{column, value}]
              end
            else
              query
            end
          end)
      {:like_search, _}, query -> query
    end)
    |> Repo.all()
  end
end

defmodule Column do
  use Surface.Component, slot: "columns"

  prop field, :string
  prop label, :string
  prop sortable, :boolean, default: true
  prop searchable, :boolean, default: true
  prop presenter, :fun
end
