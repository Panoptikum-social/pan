defmodule PanWeb.Surface.Admin.Explorer do
  use Surface.LiveComponent
  alias PanWeb.Surface.Admin.Tools

  prop(title, :string, required: false, default: "Items")
  prop(class, :css_class, required: false)
  prop(items, :list, required: true)

  slot(cols, props: [item: ^items])
  slot(toolbar, as: :toolbar_content)
  data(selected, :integer)

  def update(assigns, socket) do
    items =
      assigns.items
      |> Tools.ensure_ids_and_selected()

    send self(), {:items, items}

    socket =
      assign(socket, assigns)
      |> assign(toolbar_content: :toolbar_content, items: items)

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

      <table class="m-1">
        <thead>
          <tr>
            <th :for={{ col <- @cols }}
                class="px-2 py-1 border border-gray-lightest bg-white italic text-center">
              {{ col.title }}
            </th>
          </tr>
        </thead>
        <tbody>
          <tr :for={{ item <- @items }}
              phx-click="select" phx-value-id={{ item.id }}
              class={{ "bg-sunflower-lighter": item.selected, "bg-white": !item.selected }}>
            <td :for.with_index={{ {col, index} <- @cols }}
                class={{ "px-1 border border-gray-lightest", col.class}}>
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
