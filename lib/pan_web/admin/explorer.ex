defmodule PanWeb.Admin.Explorer do
  use PanWeb, :live_component
  alias PanWeb.Admin.Tools

  def update(assigns, socket) do
    items = Tools.ensure_ids_and_selected(assigns.items)
    send(self(), {:items, items})
    {:ok, assign(socket, assigns) |> assign(items: items)}
  end

  slot :toolbar_items do
    attr :message, :string, required: true
    attr :title, :string, required: true
    attr :when_selected_count, :atom
  end

  slot :cols do
    attr :title, :string, required: true
    attr :class, :string
  end

  def render(assigns) do
    ~H"""
    <div id={@id}
         class={["m-2 border border-gray rounded", @class]}>
      <h1 class="p-1 border-b border-t-rounded border-gray text-center bg-linear-to-r from-gray-light
                via-gray-lighter to-gray-light font-mono">
        {@title}
      </h1>

      <div :if={@toolbar_items != []}
           class="flex flex-col sm:flex-row justify-start bg-linear-to-r from-gray-lightest
                  via-gray-lighter to-gray-light space-x-5 border-b border-gray">
        <button :for={toolbar_item <- @toolbar_items}
                phx-click={toolbar_item.message}
                disabled={Tools.disabled?(toolbar_item.when_selected_count, @selected_count)}
                class="border border-gray bg-white hover:bg-gray-lightest px-1 py-0.5
                       lg:px-2 lg:py-0 m-1 rounded disabled:opacity-50 disabled:bg-gray-lightest disabled:pointer-events-none">
          {toolbar_item.title}
        </button>
      </div>

      <table :if={@format == :table} class="m-1 w-full">
        <thead>
          <tr>
            <th :for={col <- @cols}
                class="px-2 py-1 border border-gray-lightest bg-white italic text-center">
              {col.title}
            </th>
          </tr>
        </thead>
        <tbody>
          <tr :for={item <- @items}
              phx-click="select"
              phx-value-id={item.id}
              class={["cursor-pointer",
                      if(item.selected, do: "bg-sunflower-lighter", else: "bg-white")]}>
            <td :for={col <- @cols}
                class={["px-1 border border-gray-lightest", col[:class]]}>
              {render_slot(col, item)}
            </td>
          </tr>
        </tbody>
      </table>

      <div :if={@format == :grid} class="grid grid-flow-col grid-rows-6">
        <div :for={item <- @items}
             phx-click="select"
             phx-value-id={item.id}
             class={["cursor-pointer m-1",
                     if(item.selected, do: "bg-sunflower-lighter", else: "bg-white")]}>
          {render_slot(@cols, item)}
        </div>
      </div>
    </div>
    """
  end
end
