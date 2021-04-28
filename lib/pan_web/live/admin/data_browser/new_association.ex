defmodule PanWeb.Live.Admin.Databrowser.NewAssociation do
  use Surface.LiveView,
    layout: {PanWeb.LayoutView, "live_admin.html"},
    container: {:div, class: "flex-1 w-full"}

  alias PanWeb.Surface.Admin.Naming
  alias PanWeb.Surface.Admin.RecordForm

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

    model = Naming.model_from_join_through(resource)

    cols =
      model.__schema__(:fields)
      |> Enum.map(&%{field: &1, type: Naming.type_of_field(model, &1)})

    struct =
      Kernel.struct(model)
      |> Map.put(first_column |> String.to_atom, first_id)
      |> Map.put(second_column |> String.to_atom, second_id)

    {:ok,
     assign(socket,
       resource: resource,
       model: model,
       cols: cols,
       record: struct
     )}
  end

  def handle_info(
        {:redirect, %{path: path, flash_type: flash_type, message: message}},
        socket
      ) do
    {:noreply,
     socket
     |> put_flash(flash_type, message)
     |> push_redirect(to: path)}
  end

  def render(assigns) do
    ~H"""
    <RecordForm id={{ "record_form_" <> @resource <> "_new" }}
                record={{ @record }}
                model={{ @model }}
                cols={{ @cols }} />
    """
  end
end
