defmodule PanWeb.Surface.Tree do
  use Surface.LiveComponent
  alias PanWeb.Surface.Node

  prop nodes, :list, required: true
  prop class, :css_class
  prop indentation_level, :integer, required: false, default: 0
  prop select, :event
  prop selected_id, :integer

  def render(assigns) do
    ~F"""
    <div class={"flex flex-col", @class}>
      {#for node <- @nodes}
        <Node id={"node-#{node.id}"}
              select={@select}
              selected_id={@selected_id}
              node={node}
              indentation_level={@indentation_level}/>
      {/for}
    </div>
    """
  end
end
