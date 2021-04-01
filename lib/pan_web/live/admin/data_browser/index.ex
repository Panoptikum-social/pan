defmodule PanWeb.Live.Admin.Databrowser.Index do
  use Surface.LiveView, layout: {PanWeb.LayoutView, "live_admin.html"}
  alias PanWeb.Surface.Admin.Naming
  alias PanWeb.Surface.Admin.Grid

  def mount(%{"resource" => resource}, _session, socket) do
    model = Naming.model_from_resource(resource)
    cols = Enum.map(Naming.index_fields(model),
                    &%{field: &1,
                       label: Naming.title_from_field(&1),
                       type: Naming.type_of_field(model, &1),
                       searchable: true,
                       sortable: true})

    {:ok, assign(socket, model: model, cols: cols)}
  end

  def render(assigns) do
    ~H"""
    <Grid id="databrowser_grid"
          heading={{ "Listing " <> Naming.model_in_plural(@model) }}
          model={{ @model }}
          cols={{ @cols }}>
    </Grid>
    """
  end
end
