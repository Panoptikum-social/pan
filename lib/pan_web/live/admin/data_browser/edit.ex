defmodule PanWeb.Live.Admin.Databrowser.Edit do
  use Surface.LiveView, layout: {PanWeb.LayoutView, "live_admin.html"},
                        container: {:div, class: "flex-1 w-full"}
  alias PanWeb.Surface.Admin.Naming
  alias PanWeb.Surface.Admin.RecordForm
  alias Pan.Repo

  def mount(%{"resource" => resource, "id" => id}, _session, socket) do
    model = Naming.model_from_resource(resource)
    cols = model.__schema__(:fields)
    |> Enum.map(&%{field: &1,
                   type: Naming.type_of_field(model, &1)})
    {:ok, assign(socket, resource: resource,
                         model: model,
                         cols: cols,
                         record: Repo.get!(model, String.to_integer(id)))}
  end

  def handle_info({:redirect, %{path: path,
                                flash_type: flash_type,
                                message: message}}, socket) do
    {:noreply,
     socket
     |> put_flash(flash_type, message)
     |> push_redirect(to: path)}
  end

  def render(assigns) do
    ~F"""
    <RecordForm id={"record_form_" <> @resource <> "_" <> Integer.to_string(@record.id)}
                {=@record}
                {=@model}
                {=@cols} />
    """
  end
end
