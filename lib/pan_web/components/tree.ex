defmodule PanWeb.Component.Tree do
  use PanWeb, :live_component
  import PanWeb.CoreComponents
  alias PanWeb.Component.Icon

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

  attr :nodes, :list, required: true
  attr :class, :string, default: nil
  attr :select, :string, default: nil
  attr :selected_id, :integer, default: nil

  def render(assigns) do
    assigns = Map.put_new(assigns, :expanded, %{})

    ~H"""
    <div class={["flex flex-col", @class]}>
      {render_tree(assigns, @nodes, 0, @myself)}
    </div>
    """
  end

  defp render_tree(assigns, nodes, indentation_level, myself) do
    assigns =
      assigns
      |> Map.put(:nodes, nodes)
      |> Map.put(:indentation_level, indentation_level)
      |> Map.put(:myself, myself)

    ~H"""
    <%= for node <- @nodes do %>
      <div phx-click={@select}
           phx-value-node-id={node.id}
           class={["px-2 py-0.5 border border-gray-light", @selected_id == node.id && "bg-success"]}>
        <span class="font-mono text-gray-light">
          {raw(String.duplicate("&nbsp;", @indentation_level))}
        </span>

        <button :if={is_list(node.children) && length(node.children) > 0}
                phx-click="toggle-expand"
                phx-value-node-id={node.id}
                phx-target={@myself}>
          <Icon.render :if={@expanded[node.id]}  name="folder-open-heroicons-outline" />
          <Icon.render :if={!@expanded[node.id]} name="folder-heroicons-outline" />
        </button>

        {node.title}
      </div>
      <%= if @expanded[node.id] && is_list(node.children) do %>
        {render_tree(assigns, node.children, @indentation_level + 1, @myself)}
      <% end %>
    <% end %>
    """
  end
end
