defmodule PanWeb.Live.Admin.Databrowser.Index do
  use Surface.LiveView, layout: {PanWeb.LayoutView, "live_admin.html"}

  def mount(%{"resource" => resource}, _session, socket) do
    {:ok, assign(socket, resource: resource)}
  end

  def render(assigns) do
    ~H"""
    The resource is {{ @resource }}.
    """
  end
end
