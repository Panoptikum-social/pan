defmodule PanWeb.Surface.Admin.IndexGrid do
  use Surface.LiveComponent
  alias PanWeb.Surface.Admin.Naming
  alias PanWeb.Surface.Admin.{Pagination, PerPageLink, DataTable, QueryBuilder}
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
  data(search_mode, :atom, values: [:exact, :starts_with, :ends_with, :contains], default: :exact)
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

  def handle_event("delete", %{"id" => id_string}, socket) do
    id = String.to_integer(id_string)
    model = socket.assigns.model
    path_helper = socket.assigns.path_helper

    try do
      QueryBuilder.delete(model, id)
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

        <div :if={{ @navigation }}
            class="flex flex-col sm:flex-row justify-start bg-gradient-to-r from-gray-lightest
                    via-gray-lighter to-gray-light space-x-6 border-b border-gray">
          <div class="mx-2 border-l border-gray-lightest">
            <PerPageLink delta="-5" target={{ @myself }}/>
            <PerPageLink delta="-3" target={{ @myself }}/>
            <PerPageLink delta="-1" target={{ @myself }}/>
            <span class="hidden sm:inline">Records</span>
            <PerPageLink delta="+1" target={{ @myself }}/>
            <PerPageLink delta="+3" target={{ @myself }}/>
            <PerPageLink delta="+5" target={{ @myself }}/>
          </div>
          <LiveRedirect :if={{ @navigation }}
                        to={{ Naming.path %{socket: @socket, model: @model, method: :new, path_helper: @path_helper} }}
                        label="New Record"
                        class="border border-gray bg-white hover:bg-gray-lightest px-1 py-0.5
                              lg:px-2 lg:py-0 m-1 rounded" />

          <button :if={{ tuple_size(@search_filter) > 0 && @navigation }}
                  :on-click={{"toggle_hide_filtered", target: @myself }}
                  class="border border-gray bg-white hover:bg-lightest px-1 py-0.5 lg:px-2 lg:py-0 m-1 rounded">
            {{ if @hide_filtered, do: "Unrelated are hidden", else: "Assigned are dyed" }}
          </button>
        </div>

        <Pagination :if={{ @navigation }}
                    per_page={{ @per_page}}
                    class="pl-2 border-b border-gray rounded-b bg-gradient-to-r from-gray-lightest
                           via-gray-lighter to-gray-light"
                    page={{ @page }}
                    target={{ @myself }} />

        <DataTable id={{ "index_table-" <> @id }}
                   target={{ @id }}
                   cols={{ @cols }}
                   model={{ @model }}
                   records={{ @records }}
                   path_helper={{ @path_helper }}
                   sort_by={{ @sort_by}}
                   sort_order={{ @sort_order }}
                   navigation={{ @navigation }}
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
