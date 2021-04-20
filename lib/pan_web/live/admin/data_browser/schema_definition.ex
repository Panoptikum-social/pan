defmodule PanWeb.Live.Admin.Databrowser.SchemaDefinition do
  use Surface.LiveView, layout: {PanWeb.LayoutView, "live_admin.html"},
                        container: {:div, class: "flex-1"}
  alias PanWeb.Surface.Admin.Naming
  require Integer

  def mount(%{"resource" => resource}, _session, socket) do
    model = Naming.model_from_resource(resource)
    {:ok, assign(socket, resource: resource, model: model)}
  end

  def render(assigns) do
    ~H"""
    <div class="m-2 border border-gray rounded">
      <h3 class="p-1 border-b border-gray text-center bg-gradient-to-r from-gray-light via-gray-lighter to-gray-light font-mono">
        Schema Definition for Resource
        <span class="italic">{{ Naming.module_without_namespace(@model) }}</span>
      </h3>

      t.b.d.
    </div>
    """
  end
end
