defmodule PanWeb.Surface.Admin.Explorer do
  use Surface.LiveComponent

  prop(title, :string, required: false, default: "Items")
  prop(class, :css_class, required: false)
  prop(items, :list, required: true)

  slot(cols, props: [item: ^items])
  slot(toolbar, as: :toolbar_content)
  data(selected, :integer)

  def update(assigns, socket) do
    items =
      assigns.items
      |> Enum.with_index()
      |> Enum.map(fn {item, index} -> Map.put_new(item, :id, index) end)

    socket =
      assign(socket, assigns)
      |> assign(items: items)
      |> assign(toolbar_content: :toolbar_content)

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div id={{ @id }} class={{ "m-2 border border-gray rounded", @class }}>
      <h2 class="p-1 border-b border-t-rounded border-gray text-center bg-gradient-to-r from-gray-light
                via-gray-lighter to-gray-light font-mono">
        {{ @title }}
      </h2>

      <div :if={{ @toolbar_content }}
           class="flex flex-col sm:flex-row justify-start bg-gradient-to-r from-gray-lightest
                  via-gray-lighter to-gray-light space-x-6 border-b border-gray">
        <slot name="toolbar"/>
      </div>

      <table>
        <thead>
          <tr>
            <th :for={{ col <- @cols }}
                class="px-2 py-1 border border-gray-lightest bg-white italic text-center">
              {{ col.title }}
            </th>
          </tr>
        </thead>
        <tbody>
          <tr :for={{ item <- @items }}>
            <td :for.with_index={{ {col, index} <- @cols }}
                class={{ "px-1 border border-gray-lightest bg-white", col.class}}>
               <slot name="cols"
                    index={{ index }}
                    :props={{ item: item }} />
            </td>
          </tr>
        </tbody>
      </table>
    </div>
    """
  end
end
