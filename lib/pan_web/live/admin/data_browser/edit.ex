defmodule PanWeb.Live.Admin.Databrowser.Edit do
  use Surface.LiveView, layout: {PanWeb.LayoutView, "live_admin.html"},
                        container: {:div, class: "flex-1 w-full"}
  alias PanWeb.Surface.Admin.Naming
  alias PanWeb.Surface.Admin.RecordForm

  def mount(%{"resource" => resource, "id" => id}, _session, socket) do
    model = Naming.model_from_resource(resource)
    cols = model.__schema__(:fields)
    |> Enum.map(&%{field: &1,
                   type: Naming.type_of_field(model, &1)})
    record =
      String.to_integer(id)
      |> model.get_by_id()

    {:ok, assign(socket, resource: resource,
                         model: model,
                         cols: cols,
                         record: record)}
  end

  def handle_info({:redirect, %{path: path,
                                flash_type: flash_type,
                                message: message}}, socket) do
    {:noreply,
     socket
     |> put_flash(flash_type, message)
     |> redirect(to: path)}
  end

  def render(assigns) do
    ~H"""
    <RecordForm id={{ "record_form_" <> @resource <> "_" <> Integer.to_string(@record.id) }}
                record={{ @record }}
                model={{ @model }}
                path_helper={{ :podcast_path }}
                cols={{ @cols }} />
    """
  end
end
