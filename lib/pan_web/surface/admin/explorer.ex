defmodule PanWeb.Surface.Admin.Explorer do
  use Surface.LiveComponent
  alias PanWeb.Surface.Admin.Tools

  prop(title, :string, required: false, default: "Items")
  prop(class, :css_class, required: false)
  prop(items, :list, required: true)
  prop(selected_count, :integer, required: false, default: 0)
  prop(format, :atom, required: false, values: [:grid, :table], default: :grid)
  prop(grid_columns, :integer, required: false, values: [1, 2, 3, 4, 5, 6], default: 5)
  prop(caller, :module, required: false)
  prop(caller_id, :string, required: false)

  slot(toolbar_items)
  slot(cols, props: [item: ^items])

  data(selected, :integer)

  def update(assigns, socket) do
    items =
      assigns.items
      |> Tools.ensure_ids_and_selected()

    send(self(), {:items, items})

    {:ok,
     socket
     |> assign(assigns)
     |> assign(
       id: assigns.id,
       items: items
     )}
  end

  def render(assigns) do
    ~H"""
    <div id={{ @id }} class={{ "m-2 border border-gray rounded", @class }}>
      <h2 class="p-1 border-b border-t-rounded border-gray text-center bg-gradient-to-r from-gray-light
                via-gray-lighter to-gray-light font-mono">
        {{ @title }}
      </h2>

      <div :if={{ @toolbar_items }}
           class="flex flex-col sm:flex-row justify-start bg-gradient-to-r from-gray-lightest
                  via-gray-lighter to-gray-light space-x-5 border-b border-gray">
        <button :for={{ toolbar_item <- @toolbar_items }}
                phx-click={{ toolbar_item.message }}
                :attrs={{ disabled: disabled?(toolbar_item, @selected_count) }}
                class="border border-gray bg-white hover:bg-gray-lightest px-1 py-0.5
                       lg:px-2 lg:py-0 m-1 rounded disabled:opacity-50 disabled:bg-gray-lightest disabled:pointer-events-none">
          {{ toolbar_item.title }}
        </button>
      </div>

      <table :if={{ @format == :table}}
             class="m-1 w-full">
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
              class={{ "cursor-pointer",
                       "bg-sunflower-lighter": item.selected,
                       "bg-white": !item.selected }}>
            <td :for.with_index={{ {col, index} <- @cols }}
                class={{ "px-1 border border-gray-lightest", col.class}}>
               <slot name="cols"
                    index={{ index }}
                    :props={{ item: item }} />
            </td>
          </tr>
        </tbody>
      </table>

      <div :if={{ @format == :grid}}
           class={{ "grid",
                    "grid-cols-1": (@grid_columns == 1),
                    "grid-cols-2": (@grid_columns == 2),
                    "grid-cols-3": (@grid_columns == 3),
                    "grid-cols-4": (@grid_columns == 4),
                    "grid-cols-5": (@grid_columns == 5),
                    "grid-cols-6": (@grid_columns == 6) }} >
        <div :for={{ item <- @items }}
             phx-click="select" phx-value-id={{ item.id }}
             class={{ "cursor-pointer m-1",
                      "bg-sunflower-lighter": item.selected,
                      "bg-white": !item.selected }}>
          <slot name="cols"
                index=0
                :props={{ item: item }} />
        </div>
      </div>
    </div>
    """
  end

  def disabled?(item, selected_count) do
    enabled =
      case item.when_selected_count do
        :any -> true
        :zero -> selected_count == 0
        :one -> selected_count == 1
        :two -> selected_count == 2
        :nonzero -> selected_count > 0
      end

    !enabled
  end
end
