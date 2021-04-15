defmodule PanWeb.Live.Admin.Databrowser.Index do
  use Surface.LiveView, layout: {PanWeb.LayoutView, "live_admin.html"},
                        container: {:div, class: "flex-1"}
  alias PanWeb.Surface.Admin.Naming
  alias PanWeb.Surface.Admin.Grid
  require Integer

  def mount(%{"resource" => resource}, _session, socket) do
    model = Naming.model_from_resource(resource)
    columns = Naming.index_fields(model) || model.__schema__(:fields)
    cols = Enum.map(columns, &%{field: &1,
                                label: Naming.title_from_field(&1),
                                type: Naming.type_of_field(model, &1),
                                searchable: true,
                                sortable: true})

    {:ok, assign(socket, model: model, cols: cols, resource: resource)}
  end

  def get_indices(assigns) do
    table_name = assigns.resource |> Naming.pluralize()
    response = Ecto.Adapters.SQL.query(Pan.Repo, "SELECT indexname, indexdef FROM pg_indexes WHERE tablename = '#{table_name}' ORDER BY indexname;")
    {:ok, %Postgrex.Result{rows: indices}} = response
    indices
  end

  def render(assigns) do
    ~H"""
    <Grid id="databrowser_grid"
          heading={{ "Listing records for " <> Naming.model_in_plural(@model) }}
          model={{ @model }}
          cols={{ @cols }}>
    </Grid>

    <div class="m-2 border border-gray rounded">
      <h3 class="p-1 border-b border-gray text-center bg-gradient-to-r from-gray-light via-gray-lighter to-gray-light font-mono">
        Indices
      </h3>
      <div class="grid mb-1"
           style="grid-template-columns: max-content 1fr;">
          <div class="px-2 font-semibold py-0.5 text-gray-darker italic text-right">Index Name</div>
          <div class="w-full font-semibold pl-4 pr-2 py-0.5">Index Definition</div>
        <For each={{ {[name, definition], index} <- Enum.with_index(get_indices(assigns)) }}>
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
