defmodule PanWeb.Surface.Node do
  use Surface.LiveComponent
  alias PanWeb.Surface.{Tree, Icon}

  prop node, :map, required: true
  prop class, :css_class
  prop indentation_level, :integer, required: false, default: 0
  data expanded, :boolean, default: false
  prop select, :event
  prop selected_id, :integer

  def handle_event("toggle-expand", _, socket) do
    {:noreply, update(socket, :expanded, &(!&1))}
  end

  def render(assigns) do
    ~F"""
    <div>
      <div :on-click={@select}
           phx-value-node-id={@node.id}
           class={"px-2 py-0.5 border border-gray-light",
                  @class,
                  "bg-success": @selected_id == @node.id}>
        {indentation(assigns, @indentation_level)}
        <button :if={@node.children |> is_list && length(@node.children) > 0}
                :on-click="toggle-expand">
           <Icon :if={@expanded}  name="folder-open-heroicons-outline" />
           <Icon :if={!@expanded} name="folder-heroicons-outline" />
        </button>
         {@node.title}
      </div>
      <Tree :if={@expanded && is_list(@node.children)}
            nodes={@node.children}
            id={"subtree-#{@node.id}"}
            select={@select}
            selected_id={@selected_id}
            indentation_level={@indentation_level + 1}/>
    </div>
    """
  end

  defp indentation(assigns, times) do
    ~F"""
    <span class="font-mono text-gray">
      {String.duplicate(".", times) |> raw}
    </span>
    """
  end
end
