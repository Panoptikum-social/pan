defmodule PanWeb.Live.Admin.Databrowser.Show do
  use PanWeb, :admin_live_view
  alias PanWeb.Admin.Naming
  alias PanWeb.Admin.ActionButtons
  alias PanWeb.Admin.RecordCard
  alias Pan.Repo

  def mount(%{"resource" => resource, "id" => id}, _session, socket) do
    model = Naming.model_from_resource(resource)

    cols =
      model.__schema__(:fields)
      |> Enum.map(&%{field: &1, type: Naming.type_of_field(model, &1)})

    {:ok,
     assign(socket,
       resource: resource,
       model: model,
       cols: cols,
       record: Repo.get!(model, String.to_integer(id))
     )}
  end

  def render(assigns) do
    ~H"""
    <.live_component module={RecordCard}
                id={"record_card_" <> @resource <> "_" <> Integer.to_string(@record.id)}
                record={@record}
                model={@model}
                cols={@cols} />
    <ActionButtons.render model={@model}
                   record={@record}
                   type={:show} />
    """
  end
end
