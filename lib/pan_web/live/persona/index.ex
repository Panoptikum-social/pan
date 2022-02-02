defmodule PanWeb.Live.Persona.Index do
  use Surface.LiveView, container: {:div, class: "m-4"}
  alias PanWeb.Persona
  alias PanWeb.Surface.Admin.IndexGrid

  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "Personas")}
  end

  def handle_info({:count, id: id, module: module}, socket) do
    send_update(module, id: id, count: :now)
    {:noreply, socket}
  end

  def render(assigns) do
    ~F"""
    <h1 class="text-3xl">All Personas</h1>

    <IndexGrid id="persona-indexgrid"
               heading="Listing records for Personas"
               model={Persona}
               path_helper={:persona_frontend_path}
               cols={[
                 %{field: :id, label: "Id", type: :integer, searchable: true, sortable: true},
                 %{field: :name, label: "Name", type: :string, searchable: true, sortable: true},
                 %{field: :pid, label: "PanoptikumID", type: :string, searchable: true, sortable: true}
                     ]}
               buttons={[:show_frontend, :pagination, :number_of_records, :search]} />

    """
  end
end
