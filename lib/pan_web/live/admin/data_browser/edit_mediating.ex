defmodule PanWeb.Live.Admin.Databrowser.EditMediating do
  use Surface.LiveView,
    layout: {PanWeb.LayoutView, "live_admin.html"},
    container: {:div, class: "flex-1 w-full"}

  alias PanWeb.Surface.Admin.{Naming, RecordForm, QueryBuilder}

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
         QueryBuilder.read_single_record(model, first_column, first_id, second_column, second_id)
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
    <RecordForm id={{ "record_form_" <> @resource <> "_" <> @ids_string }}
                record={{ @record }}
                model={{ @model }}
                cols={{ @cols }} />
    """
  end
end
