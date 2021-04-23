defmodule PanWeb.Live.Admin.Databrowser.DbIndex do
  use Surface.LiveView, layout: {PanWeb.LayoutView, "live_admin.html"},
                        container: {:div, class: "flex-1"}
  alias PanWeb.Surface.Admin.Naming
  require Integer

  def mount(%{"resource" => resource}, _session, socket) do
    model = Naming.model_from_resource(resource)
    {:ok, assign(socket, resource: resource, model: model)}
  end

  def get_indices(assigns) do
    table_name = Naming.table_name(assigns.model)
    response =
      Ecto.Adapters.SQL.query(Pan.Repo, "SELECT indexname, indexdef FROM pg_indexes WHERE tablename = '#{table_name}' ORDER BY indexname;")
    {:ok, %Postgrex.Result{rows: indices}} = response
    indices
  end

  def render(assigns) do
    ~H"""
    <div class="m-2 border border-gray rounded">
      <h3 class="p-1 border-b border-gray text-center bg-gradient-to-r from-gray-light via-gray-lighter to-gray-light font-mono">
        Database Indices for Resource
        <span class="italic">{{ Naming.module_without_namespace(@model) }}</span>
      </h3>
      <div class="grid mb-1"
           style="grid-template-columns: max-content 1fr;">
          <div class="px-2 font-semibold py-0.5 text-gray-darker italic text-right">Index Name</div>
          <div class="w-full font-semibold pl-4 pr-2 py-0.5">Index Definition</div>
        <For each={{ {[name, definition], index} <- get_indices(assigns) |> Enum.with_index }}>
          <div class={{ "px-2 py-0.5 text-gray-darker italic text-right",
                        "bg-white": Integer.is_even(index),
                        "bg-gray-lightest": Integer.is_odd(index),
                        "border-t-2 border-gray-lighter": index > 0 }}>
            {{ name }}
          </div>
          <div class={{ "w-full pl-4 pr-2 py-0.5",
                        "bg-white": Integer.is_even(index),
                        "bg-gray-lightest": Integer.is_odd(index),
                        "border-t-2 border-gray-lighter": index > 0 }}>
            {{definition}}
          </div>
        </For>
      </div>
    </div>
    """
  end
end
