defmodule PanWeb.Live.Admin.Databrowser.ShowMediating do
  use Surface.LiveView, layout: {PanWeb.LayoutView, "live_admin.html"}
  alias PanWeb.Surface.Admin.{Naming, RecordCard, QueryBuilder}

  def mount(
        %{
          "resource" => resource,
          "first_column" => first_column,
          "first_id" => first_id,
          "second_column" => second_column,
          "second_id" => second_id
        },
        _session,
        socket
      ) do
    model = Naming.model_from_resource(resource)

    cols =
      model.__schema__(:fields)
      |> Enum.map(&%{field: &1, type: Naming.type_of_field(model, &1)})

    {:ok,
     assign(socket,
       resource: resource,
       model: model,
       cols: cols,
       ids_string: first_id <> "_" <> second_id,
       record:
         QueryBuilder.read_by_params(model, %{
           first_column => first_id,
           second_column => second_id
         })
     )}
  end

  def render(assigns) do
    ~F"""
    <RecordCard id={"record_card_" <> @resource <> "_" <> @ids_string}
                record={@record}
                model={@model}
                cols={@cols} />
    """
  end
end
