defmodule PanWeb.Live.Admin.Databrowser.Index do
  use Surface.LiveView,
    layout: {PanWeb.LayoutView, :live_admin},
    container: {:div, class: "flex-1"}

  alias PanWeb.Surface.Admin.{Naming, IndexGrid, ActionButtons}
  require Integer

  def mount(%{"resource" => resource}, _session, socket) do
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

    {:ok, assign(socket, model: model, cols: cols, resource: resource)}
  end

  def handle_info({:count, id: id, module: module}, socket) do
    if socket.assigns.admin, do: send_update(module, id: id, count: :now)
    {:noreply, socket}
  end

  def render(assigns) do
    ~F"""
    <IndexGrid id="index_table"
               heading={"Listing records for " <> Naming.model_in_plural(@model)}
               {=@model}
               {=@cols}
               buttons={[:show, :edit, :delete, :new, :pagination,
                           :number_of_records, :search]}/>
    <ActionButtons {=@model }
                   type={:index} />
    """
  end
end
