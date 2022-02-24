defmodule PanWeb.Surface.Admin.IndexGrid do
  use Surface.LiveComponent
  alias PanWeb.Endpoint
  alias PanWeb.Surface.Admin.{Naming, Pagination, PerPageLink, DataTable, QueryBuilder, Tools}
  alias Surface.Components.{LiveRedirect}
  alias PanWeb.Router.Helpers, as: Routes
  alias Pan.Repo

  prop(heading, :string, required: false, default: "Records")
  prop(model, :module, required: true)
  prop(path_helper, :atom, required: false)
  prop(cols, :list, required: false, default: [])
  prop(search_filter, :tuple, default: {})
  prop(per_page, :integer, default: 20)
  prop(class, :css_class, required: false)
  prop(buttons, :list, required: true)
  prop(records, :list, default: [])

  prop(color_class, :css_class,
    required: false,
    default: "from-bittersweet-light via-bittersweet to-bittersweet-light"
  )

  data(selected_records, :list, default: [])
  data(request_confirmation, :boolean, default: false)
  data(search_options, :map, default: %{})
  data(page, :integer, default: 1)
  data(search_mode, :atom, values: [:exact, :starts_with, :ends_with, :contains], default: :exact)
  data(hide_filtered, :boolean, default: true)
  data(sort_by, :atom, default: :id)
  data(sort_order, :atom, default: :asc)
  data(primary_key, :list, default: [])
  data(nr_of_pages, :integer, default: -1)
  data(nr_of_unfiltered, :integer)
  data(nr_of_filtered, :integer, default: -1)

  def update(%{count: :now}, socket) do
    search_criteria = [
      search: %{
        options: socket.assigns.search_options,
        filter: socket.assigns.search_filter,
        mode: socket.assigns.search_mode,
        hide: socket.assigns.hide_filtered
      }
    ]

    socket =
      assign_new(socket, :nr_of_unfiltered, fn ->
        QueryBuilder.count_unfiltered(socket.assigns.model)
      end)

    nr_of_filtered = QueryBuilder.count_filtered(socket.assigns.model, search_criteria)
    nr_of_pages = round(nr_of_filtered / socket.assigns.per_page + 0.5)

    {:ok, assign(socket, nr_of_filtered: nr_of_filtered, nr_of_pages: nr_of_pages)}
  end

  def update(assigns, socket) do
    primary_key = assigns.model.__schema__(:primary_key)

    socket =
      assign(socket, assigns)
      |> assign(primary_key: primary_key)
      |> derive_and_assign_sort_by(assigns)

    socket = if socket.assigns.records == [], do: get_records(socket), else: socket
    {:ok, socket}
  end

  defp derive_and_assign_sort_by(socket, assigns) do
    if Map.has_key?(assigns, :cols) do
      socket |> assign(sort_by: hd(assigns.cols)[:field])
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
      assign(socket,
        page: 1,
        search_options: search_options
      )
      |> get_records

    {:noreply, socket}
  end

  def handle_event("sort", %{"sort-by" => sort_by, "sort-order" => sort_order}, socket) do
    socket =
      assign(socket,
        sort_by: String.to_atom(sort_by),
        sort_order: String.to_atom(sort_order)
      )
      |> get_records

    {:noreply, socket}
  end

  def handle_event("paginate", %{"page" => page}, socket) do
    socket =
      assign(socket, page: String.to_integer(page))
      |> get_records

    {:noreply, socket}
  end

  def handle_event("cycle_search_mode", _, socket) do
    search_mode =
      case socket.assigns.search_mode do
        :exact -> :starts_with
        :starts_with -> :ends_with
        :ends_with -> :contains
        :contains -> :exact
      end

    socket =
      assign(socket, search_mode: search_mode)
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

  def handle_event("delete", _, socket) do
    model = socket.assigns.model
    [selected_record | _] = socket.assigns.selected_records

    record =
      if Map.has_key?(selected_record, :id) do
        Repo.get!(model, selected_record.id)
      else
        [first_column, second_column] = socket.assigns.primary_key

        QueryBuilder.read_by_values(model, %{
          first_column => selected_record[first_column],
          second_column => selected_record[second_column]
        })
      end

    path_helper = socket.assigns.path_helper

    try do
      QueryBuilder.delete(model, record)
      socket = assign(socket, selected_records: [], request_confirmation: false)
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

  def handle_event("select", %{"id" => id}, socket) do
    clicked_record = %{id: String.to_integer(id)}
    selected_records = socket.assigns.selected_records

    selected_records =
      if Enum.member?(selected_records, clicked_record) do
        List.delete(selected_records, clicked_record)
      else
        [clicked_record | selected_records]
      end

    {:noreply, assign(socket, selected_records: selected_records)}
  end

  def handle_event("select", %{"one" => one, "two" => two}, socket) do
    primary_key = socket.assigns.model.__schema__(:primary_key)

    clicked_record = %{
      hd(primary_key) => String.to_integer(one),
      hd(tl(primary_key)) => String.to_integer(two)
    }

    selected_records = socket.assigns.selected_records

    selected_records =
      if Enum.member?(selected_records, clicked_record) do
        List.delete(selected_records, clicked_record)
      else
        [clicked_record | selected_records]
      end

    {:noreply, assign(socket, selected_records: selected_records)}
  end

  def handle_event("show", _, socket) do
    selected_record = hd(socket.assigns.selected_records)
    resource = Phoenix.Naming.resource_name(socket.assigns.model)

    if Map.has_key?(selected_record, :id) do
      id = selected_record |> Map.get(:id)
      show_path = Routes.databrowser_path(socket, :show, resource, id)
      {:noreply, push_redirect(socket, to: show_path)}
    else
      [first_column, second_column] = socket.assigns.primary_key

      show_mediating_path =
        Routes.databrowser_path(
          socket,
          :show_mediating,
          resource,
          first_column,
          selected_record[first_column],
          second_column,
          selected_record[second_column]
        )

      {:noreply, push_redirect(socket, to: show_mediating_path)}
    end
  end

  def handle_event("show_frontend", _, socket) do
    selected_record = hd(socket.assigns.selected_records)

    if Map.has_key?(selected_record, :id) do
      path_helper = socket.assigns.path_helper
      id = selected_record |> Map.get(:id)
      show_path = Function.capture(Routes, path_helper, 3).(Endpoint, :show, id)
      {:noreply, push_redirect(socket, to: show_path)}
    end
  end

  def handle_event("edit", _, socket) do
    selected_record = hd(socket.assigns.selected_records)
    resource = Phoenix.Naming.resource_name(socket.assigns.model)

    if Map.has_key?(selected_record, :id) do
      id = selected_record.id
      edit_path = Routes.databrowser_path(socket, :edit, resource, id)
      {:noreply, push_redirect(socket, to: edit_path)}
    else
      [first_column, second_column] = socket.assigns.primary_key

      edit_mediating_path =
        Routes.databrowser_path(
          socket,
          :edit_mediating,
          resource,
          first_column,
          Map.get(selected_record, first_column),
          second_column,
          Map.get(selected_record, second_column)
        )

      {:noreply, push_redirect(socket, to: edit_mediating_path)}
    end
  end

  def handle_event("toggle_request_confirmation", _, socket) do
    {:noreply, assign(socket, request_confirmation: !socket.assigns.request_confirmation)}
  end

  def handle_event("link", _, socket) do
    selected_record_ids = Enum.map(socket.assigns.selected_records, & &1.id)

    QueryBuilder.set_belongs_to(socket.assigns, selected_record_ids)
    {:noreply, get_records(socket)}
  end

  def handle_event("unlink", _, socket) do
    selected_record_ids = Enum.map(socket.assigns.selected_records, & &1.id)

    QueryBuilder.clear_belongs_to(socket.assigns, selected_record_ids)
    {:noreply, get_records(socket)}
  end

  def handle_event("associate", _, socket) do
    selected_record_id = hd(Enum.map(socket.assigns.selected_records, & &1.id))
    send(self(), {:associate_to, selected_record_id})
    {:noreply, socket}
  end

  def get_records(socket) do
    records =
      QueryBuilder.load(socket.assigns.model, criteria(socket.assigns), socket.assigns.cols)

    send(self(), {:count, id: socket.assigns.id, module: __MODULE__})
    assign(socket, records: records)
  end

  def criteria(assigns) do
    [
      paginate: %{page: assigns.page, per_page: assigns.per_page},
      sort: %{by: assigns.sort_by, order: assigns.sort_order},
      search: %{
        options: assigns.search_options,
        filter: assigns.search_filter,
        mode: assigns.search_mode,
        hide: assigns.hide_filtered
      }
    ]
  end

  def render(assigns) do
    ~F"""
    <div {=@id}>
      <div class={"my-2 sm:m-4 border border-gray rounded shadow-lg", @class}>
        <h1 class={"p-1 border border-t-rounded border-gray-dark text-center bg-gradient-to-r
                    font-mono text-white font-semibold rounded-t", @color_class}>
          {@heading}
        </h1>

        <div class="flex flex-col sm:flex-row justify-start bg-gradient-to-r from-gray-lightest
                    via-gray-lighter to-gray-light border-b border-gray items-center">
          <div class="sm:border-r border-gray flex">
            <button :if={:show in @buttons}
                    class="border border-gray bg-white hover:bg-gray-lightest px-1 py-0.5
                           lg:px-2 lg:py-0 m-1 rounded
                           disabled:opacity-50 disabled:bg-gray-lightest disabled:pointer-events-none"
                    disabled={Tools.disabled?(:one, @selected_records |> length)}
                    :on-click="show">
                    🔍 Show
            </button>

            <button :if={:show_frontend in @buttons}
                    class="border border-gray bg-white hover:bg-gray-lightest px-1 py-0.5
                          lg:px-2 lg:py-0 m-1 rounded
                          disabled:opacity-50 disabled:bg-gray-lightest disabled:pointer-events-none"
                    disabled={Tools.disabled?(:one, @selected_records |> length)}
                    :on-click="show_frontend">
                    🔍 Show
            </button>

            <button :if={:edit in @buttons}
                    class="border border-gray bg-white hover:bg-gray-lightest px-1 py-0.5
                           lg:px-2 lg:py-0 m-1 rounded
                           disabled:opacity-50 disabled:bg-gray-lightest disabled:pointer-events-none"
                    disabled={Tools.disabled?(:one, @selected_records |> length)}
                    :on-click="edit">
                    🖊️ Edit
            </button>

            <button :if={!@request_confirmation && :delete in @buttons}
                    class="border border-gray bg-white hover:bg-gray-lightest px-1 py-0.5
                           lg:px-2 lg:py-0 m-1 rounded
                           disabled:opacity-50 disabled:bg-gray-lightest disabled:pointer-events-none"
                    disabled={Tools.disabled?(:one, @selected_records |> length)}
                    :on-click="toggle_request_confirmation">
              🗑️ Delete
            </button>

            <div :if={@request_confirmation}
                 class="px-2">
              Are you sure?
              <button class="border border-gray bg-white hover:bg-gray-lightest px-1 py-0.5
                            lg:px-2 lg:py-0 m-1 rounded
                            disabled:opacity-50 disabled:bg-gray-lightest disabled:pointer-events-none"
                      disabled={Tools.disabled?(:one, @selected_records |> length)}
                      :on-click="delete">
                Yes
              </button>
              <button class="border border-gray bg-white hover:bg-gray-lightest px-1 py-0.5
                             lg:px-2 lg:py-0 m-1 rounded
                             disabled:opacity-50 disabled:bg-gray-lightest disabled:pointer-events-none"
                      disabled={Tools.disabled?(:one, @selected_records |> length)}
                      :on-click="toggle_request_confirmation">
                No
              </button>
            </div>

            <button :if={:link in @buttons}
                    class="border border-gray bg-white hover:bg-gray-lightest px-1 py-0.5
                           lg:px-2 lg:py-0 m-1 rounded
                           disabled:opacity-50 disabled:bg-gray-lightest disabled:pointer-events-none"
                    disabled={Tools.disabled?(:nonzero, @selected_records |> length)}
                    :on-click="link">
              🔗 Link
            </button>

            <button :if={:link in @buttons}
                    class="border border-gray bg-white hover:bg-gray-lightest px-1 py-0.5
                          lg:px-2 lg:py-0 m-1 rounded
                          disabled:opacity-50 disabled:bg-gray-lightest disabled:pointer-events-none"
                    disabled={Tools.disabled?(:nonzero, @selected_records |> length)}
                    :on-click="unlink">
              ✂️ Unlink
            </button>

            <button :if={:new_mediating in @buttons}
                    class="border border-gray bg-white hover:bg-gray-lightest px-1 py-0.5
                          lg:px-2 lg:py-0 m-1 rounded
                          disabled:opacity-50 disabled:bg-gray-lightest disabled:pointer-events-none"
                    disabled={Tools.disabled?(:one, @selected_records |> length)}
                    :on-click="associate">
              ↔️ New association
            </button>

            <LiveRedirect :if={:new in @buttons}
                          to={Naming.path %{model: @model, method: :new, path_helper: @path_helper}}
                          label="🆕 New"
                          class="border border-gray bg-white hover:bg-gray-lightest py-0.5
                                lg:mr-2 px-2 lg:py-0 m-1 rounded sm:border-r border-gray" />
          </div>

          <div :if={:number_of_records in @buttons}
               class="px-4 sm:border-r border-gray">
            <PerPageLink delta="-5" click="per_page"/>
            <PerPageLink delta="-3" click="per_page"/>
            <PerPageLink delta="-1" click="per_page"/>
            <span class="hidden sm:inline">Records</span>
            <PerPageLink delta="+1" click="per_page"/>
            <PerPageLink delta="+3" click="per_page"/>
            <PerPageLink delta="+5" click="per_page"/>
          </div>

          <button :if={:assignment_filter in @buttons}
                  :on-click="toggle_hide_filtered"
                  class="border border-gray bg-white hover:bg-lightest px-1 py-0.5 lg:px-2 lg:py-0 m-1 rounded">
            {if @hide_filtered, do: "Show unassigned", else: "Hide unassigned"}
          </button>
        </div>

        <Pagination :if={:pagination in @buttons}
                    class="pl-2 border-b border-gray rounded-b bg-gradient-to-r from-gray-lightest
                           via-gray-lighter to-gray-light"
                    click="paginate"
                    {=@page}
                    {=@per_page}
                    {=@nr_of_pages}
                    nr_of_unfiltered = {Map.get(assigns, :nr_of_unfiltered)}
                    {=@nr_of_filtered} />

        <DataTable id={"index_table-#{@id}"}
                   sort="sort"
                   cycle_search_mode="cycle_search_mode"
                   select="select"
                   search="search"
                   {=@cols}
                   {=@model}
                   {=@primary_key}
                   {=@records}
                   {=@selected_records}
                   {=@path_helper}
                   {=@sort_by}
                   {=@sort_order}
                   {=@buttons}
                   {=@search_mode}
                   {=@hide_filtered}
                   {=@search_options}
                   {=@search_filter} />
      </div>
    </div>
    """
  end
end
