defmodule PanWeb.Surface.Admin.Explorer do
  use Surface.LiveComponent
  alias PanWeb.Surface.Admin.Tools

  prop(title, :string, required: false, default: "Items")
  prop(class, :css_class, required: false)
  prop(items, :generator, required: true)
  prop(selected_count, :integer, required: false, default: 0)
  prop(format, :atom, required: false, values: [:grid, :table], default: :grid)
  prop(caller, :module, required: false)
  prop(caller_id, :string, required: false)

  slot(toolbar_items)
  slot(cols, generator_prop: :items)

  data(selected, :integer)

  def update(assigns, socket) do
    items = Tools.ensure_ids_and_selected(assigns.items)
    send(self(), {:items, items})

    {:ok,
     assign(socket, assigns)
     |> assign(id: assigns.id, items: items)}
  end

  def render(assigns) do
    ~F"""
    <div {=@id}
         class={"m-2 border border-gray rounded", @class}>
      <h1 class="p-1 border-b border-t-rounded border-gray text-center bg-gradient-to-r from-gray-light
                via-gray-lighter to-gray-light font-mono">
        {@title}
      </h1>

      <div :if={@toolbar_items}
           class="flex flex-col sm:flex-row justify-start bg-gradient-to-r from-gray-lightest
                  via-gray-lighter to-gray-light space-x-5 border-b border-gray">
        {#for toolbar_item <- @toolbar_items}
          <button phx-click={toolbar_item.message}
                  disabled={Tools.disabled?(toolbar_item.when_selected_count, @selected_count)}
                  class="border border-gray bg-white hover:bg-gray-lightest px-1 py-0.5
                         lg:px-2 lg:py-0 m-1 rounded disabled:opacity-50 disabled:bg-gray-lightest disabled:pointer-events-none">
            {toolbar_item.title}
          </button>
        {/for}
      </div>

      <table :if={@format == :table}
             class="m-1 w-full">
        <thead>
          <tr>
            {#for col <- @cols}
              <th class="px-2 py-1 border border-gray-lightest bg-white italic text-center">
                {col.title}
              </th>
            {/for}
          </tr>
        </thead>
        <tbody>
          {#for item <- @items}
            <tr phx-click="select"
                phx-value-id={item.id}
                class={"cursor-pointer",
                        "bg-sunflower-lighter": item.selected,
                        "bg-white": !item.selected}>
              {#for col <- @cols}
                <td class={"px-1 border border-gray-lightest", col.class}>
                  <#slot {@cols} generator_value={item} />
                </td>
              {/for}
            </tr>
        {/for}
        </tbody>
      </table>

      <div :if={@format == :grid}
           class={"grid grid-flow-col grid-rows-6"} >
        {#for item <- @items}
           <div phx-click="select"
                phx-value-id={item.id}
                class={"cursor-pointer m-1",
                       "bg-sunflower-lighter": item.selected,
                       "bg-white": !item.selected}>
            <#slot {@cols} generator_value={item} />
          </div>
        {/for}
      </div>
    </div>
    """
  end
end
