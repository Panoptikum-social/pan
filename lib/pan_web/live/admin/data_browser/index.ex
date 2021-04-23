defmodule PanWeb.Live.Admin.Databrowser.Index do
  use Surface.LiveView, layout: {PanWeb.LayoutView, "live_admin.html"},
                        container: {:div, class: "flex-1"}
  alias PanWeb.Surface.Admin.Naming
  alias PanWeb.Surface.Admin.IndexGrid
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

  def handle_info({:items, records}, socket) do
    send_update(IndexGrid, id: "index_table", records: records)
    {:noreply, socket}
  end

  def render(assigns) do
    IO.inspect (Naming.primary_key(assigns.model))
    ~H"""
    <IndexGrid id="index_table"
          heading={{ "Listing records for " <> Naming.model_in_plural(@model) }}
          model={{ @model }}
          cols={{ @cols }}
          primary_key={{ Naming.primary_key(@model) }}>
    </IndexGrid>
    """
  end
end
