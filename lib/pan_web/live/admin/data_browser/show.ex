defmodule PanWeb.Live.Admin.Databrowser.Show do
  use Surface.LiveView, layout: {PanWeb.LayoutView, :live_admin}
  alias PanWeb.Surface.Admin.{Naming, RecordCard, ActionButtons}
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
    ~F"""
    <RecordCard id={"record_card_" <> @resource <> "_" <> Integer.to_string(@record.id)}
                {=@record}
                {=@model}
                {=@cols} />
    <ActionButtons {=@model }
                   {=@record}
                   type={:show} />
    """
  end
end
