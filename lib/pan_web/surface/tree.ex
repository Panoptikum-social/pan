defmodule PanWeb.Surface.Tree do
  use Surface.LiveComponent
  alias PanWeb.Surface.Icon

  prop(nodes, :list, required: true)
  prop(class, :css_class)
  prop(select, :event)
  prop(selected_id, :integer)
  data(expanded, :map, default: %{})

  def handle_event("toggle-expand", %{"node-id" => node_id}, socket) do
    expanded = socket.assigns.expanded
    node_id = node_id |> String.to_integer()

    expanded =
      if Map.has_key?(expanded, node_id) do
        Map.delete(expanded, node_id)
      else
        Map.put(expanded, node_id, true)
      end

    {:noreply, assign(socket, :expanded, expanded)}
  end

  def render(assigns) do
    ~F"""
    <div class={"flex flex-col", @class}>
      {render_tree(assigns, @nodes, 0)}
    </div>
    """
  end

  defp render_tree(assigns, nodes, indentation_level) do
    ~F"""
    {#for node <- nodes}
      <div :on-click={@select}
           phx-value-node-id={node.id}
           class={"px-2 py-0.5 border border-gray-light",
                  "bg-success": @selected_id == node.id}>
        <span class="font-mono text-gray-light">
          {String.duplicate("&nbsp;", indentation_level) |> raw}
        </span>

        <button :if={node.children |> is_list && length(node.children) > 0}
                :on-click="toggle-expand" phx-value-node-id={node.id}>
          <Icon :if={@expanded[node.id]}  name="folder-open-heroicons-outline" />
          <Icon :if={!@expanded[node.id]} name="folder-heroicons-outline" />
        </button>

        {node.title}
      </div>
      {#if @expanded[node.id] && is_list(node.children)}
        {render_tree(assigns, node.children, indentation_level + 1)}
      {/if}
    {/for}
    """
  end
end
