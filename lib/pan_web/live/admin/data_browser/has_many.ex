defmodule PanWeb.Live.Admin.Databrowser.HasMany do
  use Surface.LiveView, layout: {PanWeb.LayoutView, "live_admin.html"}
  alias PanWeb.Surface.Admin.Naming
  alias PanWeb.Surface.Admin.Grid

  def mount(
        %{"parent_column" => parent_column, "parent_id" => parent_id, "resource" => resource},
        _session,
        socket
      ) do
    model = Naming.model_from_resource(resource)
    columns = Naming.index_fields(model) || model.__schema__(:fields)

    cols =
      Enum.map(
        columns,
        &%{
          field: &1,
          label: Naming.title_from_field(&1),
          type: Naming.type_of_field(model, &1),
          searchable: true,
          sortable: true
        }
      )

    {:ok,
     assign(socket,
       model: model,
       cols: cols,
       search_filter: {String.to_atom(parent_column), String.to_integer(parent_id)}
     )}
  end

  def render(assigns) do
    ~H"""
    <Grid id="databrowser_grid"
          heading={{ "Listing " <> Naming.model_in_plural(@model) }}
          model={{ @model }}
          cols={{ @cols }}
          search_filter={{ @search_filter }}>
    </Grid>
    """
  end
end
