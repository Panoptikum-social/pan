defmodule PanWeb.Surface.Node do
  use Surface.LiveComponent
  prop node, :map, required: true
  prop class, :css_class
  prop indent, :integer, required: false, default: 0
  data expanded, :boolean, default: false

  def handle_event("toggle", _, socket) do
    {:noreply, update(socket, :expanded, &(!&1))}
  end

  def render(assigns) do
    ~F"""
    <div class={"px-2 py-0.5 border border-gray-light", @class}>
      {indent(@indent)}
      <a :if={@node.children != []}
         :on-click={"toggle"}>+</a>
      {@node.title} ({@expanded})
    </div>
    """
  end

  defp indent(times) do
    String.duplicate("..", times)
  end
end
