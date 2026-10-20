defmodule PanWeb.Component.Tree do
  use PanWeb, :live_component
  alias PanWeb.Component.Icon

  # starts fully expanded; later updates (e.g. after a merge) keep what the
  # user opened or closed
  def update(assigns, socket) do
    socket = assign(socket, assigns)
    {:ok, assign_new(socket, :expanded, fn -> expand_all(socket.assigns.nodes) end)}
  end

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

  # collapses everything if anything is open, otherwise opens every node
  def handle_event("toggle-expand-all", _, %{assigns: %{expanded: expanded}} = socket)
      when expanded == %{} do
    {:noreply, assign(socket, :expanded, expand_all(socket.assigns.nodes))}
  end

  def handle_event("toggle-expand-all", _, socket) do
    {:noreply, assign(socket, :expanded, %{})}
  end

  defp expand_all(nodes), do: nodes |> parent_ids() |> Map.new(&{&1, true})

  defp parent_ids(nodes) do
    for %{children: [_ | _] = children} = node <- nodes,
        id <- [node.id | parent_ids(children)],
        do: id
  end

  attr :nodes, :list, required: true
  attr :class, :string, default: nil
  attr :select, :string, default: nil
  attr :selected_id, :integer, default: nil
  attr :marked, :map, default: %{}, doc: "node id => background class, below the selection"
  attr :counts, :map, default: nil, doc: "node id => number shown after the title"
  attr :badges, :map, default: %{}, doc: "node id => short label shown after the title"

  def render(assigns) do
    ~H"""
    <div class={["flex flex-col", @class]}>
      <button
        phx-click="toggle-expand-all"
        phx-target={@myself}
        class="btn btn-sm btn-outline btn-primary self-start mb-2"
      >
        <%= if @expanded == %{} do %>
          <Icon.render name="folder-open-heroicons-outline" /> Expand all
        <% else %>
          <Icon.render name="folder-heroicons-outline" /> Collapse all
        <% end %>
      </button>
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
      <div
        phx-click={@select}
        phx-value-node-id={node.id}
        class={[
          "px-2 py-0.5 border border-gray-light",
          if(@selected_id == node.id, do: "bg-success", else: @marked[node.id])
        ]}
      >
        <span class="font-mono text-gray-light">
          {raw(String.duplicate("&nbsp;", @indentation_level))}
        </span>

        <button
          :if={is_list(node.children) && length(node.children) > 0}
          phx-click="toggle-expand"
          phx-value-node-id={node.id}
          phx-target={@myself}
        >
          <Icon.render :if={@expanded[node.id]} name="folder-open-heroicons-outline" />
          <Icon.render :if={!@expanded[node.id]} name="folder-heroicons-outline" />
        </button>

        {node.title}
        <span :if={@badges[node.id]} class="badge badge-xs badge-neutral ml-1">
          {@badges[node.id]}
        </span>
        <span :if={@counts} class="ml-1 text-xs opacity-60 tabular-nums">
          {Map.get(@counts, node.id, 0)}
        </span>
      </div>
      <%= if @expanded[node.id] && is_list(node.children) do %>
        {render_tree(assigns, node.children, @indentation_level + 1, @myself)}
      <% end %>
    <% end %>
    """
  end
end
