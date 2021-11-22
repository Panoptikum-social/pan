defmodule PanWeb.Live.Admin.Databrowser.New do
  use Surface.LiveView, layout: {PanWeb.LayoutView, "live_admin.html"},
                        container: {:div, class: "flex-1 w-full"}
  alias PanWeb.Surface.Admin.Naming
  alias PanWeb.Surface.Admin.RecordForm

  def mount(%{"resource" => resource}, _session, socket) do
    model = Naming.model_from_resource(resource)
    cols = model.__schema__(:fields)
    |> Enum.map(&%{field: &1,
                   type: Naming.type_of_field(model, &1)})

    {:ok, assign(socket, resource: resource,
                         model: model,
                         cols: cols,
                         record: Kernel.struct(model))}
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
    <RecordForm id={"record_form_" <> @resource <> "_new"}
                record={@record}
                model={@model}
                cols={@cols} />
    """
  end
end
