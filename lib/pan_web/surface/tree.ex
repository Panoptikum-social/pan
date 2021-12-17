defmodule PanWeb.Surface.Tree do
  use Surface.Component
  alias PanWeb.Surface.Node

  prop nodes, :list, required: true
  prop class, :css_class
  prop indent, :integer, required: false, default: 0

  def render(assigns) do
    ~F"""
    <div class={"flex flex-col", @class}>
      {#for node <- @nodes}
        <Node id={"node-#{node.id}"}
              node={node}
              indent={@indent}/>
      {/for}
    </div>
    """
  end
end
