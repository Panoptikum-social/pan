defmodule PanWeb.Surface.Admin.IndexTable do
  use Surface.LiveComponent
  import Ecto.Query
  alias PanWeb.Surface.Admin.Naming
  alias Pan.Repo
  alias PanWeb.Surface.Admin.{Pagination, PerPageLink, DataTable, Explorer, ToolbarItem}
  alias Surface.Components.LiveRedirect

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
  data(hide_filtered, :boolean, default: true)
  data(sort_by, :atom, default: :id)
  data(sort_order, :atom, default: :asc)
  prop(records, :list, default: [])

  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> derive_and_assign_sort_by(assigns)

    socket = if socket.assigns.records == [], do: get_records(socket), else: socket

    {:ok, socket}
  end

  defp derive_and_assign_sort_by(socket, assigns) do
    if Map.has_key?(assigns, :cols) do
      socket |> assign(sort_by: List.first(assigns.cols)[:field])
    else
      socket
    end
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
          |> push_redirect(to: index_path)

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
      hide_filtered: a.hide_filtered
    ]

    assign(socket, records: load(a.model, criteria, a.cols))
  end

  defp load(model, criteria, cols) when is_list(criteria) do
    from(r in model)
    |> apply_criteria(criteria)
    |> select_columns(cols)
    |> Repo.all()
  end

  defp apply_criteria(query, criteria) do
    Enum.reduce(
      criteria,
      query,
      &apply_criterium(&1, &2, criteria[:like_search], criteria[:hide_filtered])
    )
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

  defp select_columns(query, cols) do
    column_atoms = Enum.map(cols, & &1.field)
    from(q in query, select: ^column_atoms)
  end

  def render(assigns) do
    ~H"""
    <div id={{ @id }}>
      <Explorer title={{ @heading}}
                items={{ @records }}
                id="index_table_explorer">
        <ToolbarItem title="New Record"
                     message="new_record"
                     when_selected_count={{ :any }}/>
      </Explorer>

      <div class={{ "m-2 border border-gray rounded", @class }}>
        <h2 class="p-1 border-b border-t-rounded border-gray text-center bg-gradient-to-r from-gray-light
                  via-gray-lighter to-gray-light font-mono">
          {{ @heading }}
        </h2>

        <div :if={{ @navigation }}
            class="flex flex-col sm:flex-row justify-start bg-gradient-to-r from-gray-lightest
                    via-gray-lighter to-gray-light space-x-6 border-b border-gray">
          <div class="mx-2 border-l border-gray-lightest">
            <PerPageLink delta="-5" target={{ "#" <> @id }}/>
            <PerPageLink delta="-3" target={{ "#" <> @id }}/>
            <PerPageLink delta="-1" target={{ "#" <> @id }}/>
            <span class="hidden sm:inline">Records</span>
            <PerPageLink delta="+1" target={{ "#" <> @id }}/>
            <PerPageLink delta="+3" target={{ "#" <> @id }}/>
            <PerPageLink delta="+5" target={{ "#" <> @id }}/>
          </div>
          <LiveRedirect :if={{ @navigation }}
                        to={{ Naming.path %{socket: @socket, model: @model, method: :new, path_helper: @path_helper} }}
                        label="New Record"
                        class="border border-gray bg-white hover:bg-gray-lightest px-1 py-0.5
                              lg:px-2 lg:py-0 m-1 rounded" />

          <button :if={{ @navigation }}
                  :on-click={{"toggle_hide_filtered", target: "#" <> @id }}
                  class="border border-gray bg-white hover:bg-lightest px-1 py-0.5 lg:px-2 lg:py-0 m-1 rounded">
            {{ if @hide_filtered, do: "Unrelated are hidden", else: "Assigned are dyed" }}
          </button>
        </div>

        <DataTable id="index_table"
              cols={{ @cols }}
              sort_by={{ @sort_by}}
              sort_order={{ @sort_order }}
              navigation={{ @navigation }}
              search_options={{ @search_options }}
              page={{ @page }}
              like_search={{ @like_search }}
              hide_filtered={{ @hide_filtered }}
              model={{ @model }}
              records={{ @records }}
              path_helper={{ @path_helper }}
              target={{ @id }}
              search_filter={{ @search_filter }} />

        <Pagination :if={{ @navigation }}
                    per_page={{ @per_page}}
                    class="pl-2 border-t border-gray rounded-b bg-gradient-to-r from-gray-lightest
                          via-gray-lighter to-gray-light"
                    page={{ @page }}
                    target={{ "#" <> @id }} />
      </div>
    </div>
    """
  end
end
