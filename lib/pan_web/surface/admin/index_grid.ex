defmodule PanWeb.Surface.Admin.IndexGrid do
  use Surface.LiveComponent
  alias PanWeb.Surface.Admin.Naming
  alias PanWeb.Surface.Admin.{Pagination, PerPageLink, DataTable, QueryBuilder, Tools}
  alias Surface.Components.{LiveRedirect}
  alias PanWeb.Router.Helpers, as: Routes
  alias Pan.Repo

  prop(heading, :string, required: false, default: "Records")
  prop(model, :module, required: true)
  prop(path_helper, :atom, required: false)
  prop(cols, :list, required: false, default: [])
  prop(search_filter, :tuple, default: {})
  prop(per_page, :integer, default: 20)
  prop(show_navigation, :boolean, required: false, default: true)
  prop(class, :css_class, required: false)

  data(selected_records, :list, default: [])
  data(request_confirmation, :boolean, default: false)
  data(search_options, :map, default: %{})
  data(page, :integer, default: 1)
  data(search_mode, :atom, values: [:exact, :starts_with, :ends_with, :contains], default: :exact)
  data(hide_filtered, :boolean, default: true)
  data(sort_by, :atom, default: :id)
  data(sort_order, :atom, default: :asc)
  data(primary_key, :list, default: [])
  prop(records, :list, default: [])

  def update(assigns, socket) do
    primary_key = assigns.model.__schema__(:primary_key)

    socket =
      socket
      |> assign(assigns)
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
      assign(socket, search_options: search_options)
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

  def handle_event("paginate", %{"page" => page, "per-page" => per_page}, socket) do
    socket =
      assign(socket,
        page: String.to_integer(page),
        per_page: String.to_integer(per_page)
      )
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
      socket = assign(socket, selected_records: [])
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

  def get_records(socket) do
    a = socket.assigns

    criteria = [
      paginate: %{page: a.page, per_page: a.per_page},
      sort: %{by: a.sort_by, order: a.sort_order},
      search: %{
        options: a.search_options,
        filter: a.search_filter,
        mode: a.search_mode,
        hide: a.hide_filtered
      }
    ]

    assign(socket, records: QueryBuilder.load(a.model, criteria, a.cols))
  end

  def render(assigns) do
    ~H"""
    <div id={{ @id }}>
      <div class={{ "m-2 border border-gray rounded", @class }}>
        <h2 class="p-1 border-b border-t-rounded border-gray text-center bg-gradient-to-r from-gray-light
                  via-gray-lighter to-gray-light font-mono">
          {{ @heading }}
        </h2>

        <div :if={{ @show_navigation }}
            class="flex flex-col sm:flex-row justify-start bg-gradient-to-r from-gray-lightest
                    via-gray-lighter to-gray-light border-b border-gray items-center">
          <div class="border-r border-gray flex">
            <button class="border border-gray bg-white hover:bg-gray-lightest px-1 py-0.5
                           lg:px-2 lg:py-0 m-1 rounded
                           disabled:opacity-50 disabled:bg-gray-lightest disabled:pointer-events-none"
                    :attrs={{ disabled: Tools.disabled?(:one, @selected_records |> length) }}
                    phx-click="show"
                    phx-target={{ @myself }}>
                    🔍 Show
            </button>

            <button class="border border-gray bg-white hover:bg-gray-lightest px-1 py-0.5
                           lg:px-2 lg:py-0 m-1 rounded
                           disabled:opacity-50 disabled:bg-gray-lightest disabled:pointer-events-none"
                    :attrs={{ disabled: Tools.disabled?(:one, @selected_records |> length) }}
                    phx-click="edit"
                    phx-target={{ @myself }}>
                    🖊️ Edit
            </button>

            <button :if={{ !@request_confirmation }}
                    class="border border-gray bg-white hover:bg-gray-lightest px-1 py-0.5
                           lg:px-2 lg:py-0 m-1 rounded
                           disabled:opacity-50 disabled:bg-gray-lightest disabled:pointer-events-none"
                    :attrs={{ disabled: Tools.disabled?(:one, @selected_records |> length) }}
                    phx-click="toggle_request_confirmation"
                    phx-target={{ @myself }}>
              🗑️ Delete
            </button>

            <div :if={{ @request_confirmation }}
                 class="px-2">
              Are you sure?
              <button class="border border-gray bg-white hover:bg-gray-lightest px-1 py-0.5
                            lg:px-2 lg:py-0 m-1 rounded
                            disabled:opacity-50 disabled:bg-gray-lightest disabled:pointer-events-none"
                      :attrs={{ disabled: Tools.disabled?(:one, @selected_records |> length) }}
                      phx-click="delete"
                      phx-target={{ @myself }}>
                Yes
              </button>
              <button class="border border-gray bg-white hover:bg-gray-lightest px-1 py-0.5
                            lg:px-2 lg:py-0 m-1 rounded
                            disabled:opacity-50 disabled:bg-gray-lightest disabled:pointer-events-none"
                      :attrs={{ disabled: Tools.disabled?(:one, @selected_records |> length) }}
                      phx-click="toggle_request_confirmation"
                      phx-target={{ @myself }}>
                No
              </button>
            </div>

            <LiveRedirect :if={{ @show_navigation }}
                          to={{ Naming.path %{socket: @socket, model: @model, method: :new, path_helper: @path_helper} }}
                          label="🆕 New"
                          class="border border-gray bg-white hover:bg-gray-lightest py-0.5
                                lg:mr-2 px-2 lg:py-0 m-1 rounded border-r border-gray" />
          </div>

          <div class="px-4 border-r border-gray">
            <PerPageLink delta="-5" target={{ @myself }}/>
            <PerPageLink delta="-3" target={{ @myself }}/>
            <PerPageLink delta="-1" target={{ @myself }}/>
            <span class="hidden sm:inline">Records</span>
            <PerPageLink delta="+1" target={{ @myself }}/>
            <PerPageLink delta="+3" target={{ @myself }}/>
            <PerPageLink delta="+5" target={{ @myself }}/>
          </div>

          <button :if={{ tuple_size(@search_filter) > 0 && @show_navigation }}
                  :on-click={{"toggle_hide_filtered", target: @myself }}
                  class="border border-gray bg-white hover:bg-lightest px-1 py-0.5 lg:px-2 lg:py-0 m-1 rounded">
            {{ if @hide_filtered, do: "Unrelated are hidden", else: "Assigned are dyed" }}
          </button>
        </div>

        <Pagination :if={{ @show_navigation }}
                    per_page={{ @per_page}}
                    class="pl-2 border-b border-gray rounded-b bg-gradient-to-r from-gray-lightest
                           via-gray-lighter to-gray-light"
                    page={{ @page }}
                    target={{ @myself }} />

        <DataTable id={{ "index_table-" <> @id }}
                   target={{ @id }}
                   cols={{ @cols }}
                   model={{ @model }}
                   primary_key={{ @primary_key }}
                   records={{ @records }}
                   selected_records={{ @selected_records }}
                   path_helper={{ @path_helper }}
                   sort_by={{ @sort_by}}
                   sort_order={{ @sort_order }}
                   show_navigation={{ @show_navigation }}
                   page={{ @page }}
                   search_mode={{ @search_mode }}
                   hide_filtered={{ @hide_filtered }}
                   search_options={{ @search_options }}
                   search_filter={{ @search_filter }} />
      </div>
    </div>
    """
  end
end
