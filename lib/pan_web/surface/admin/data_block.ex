defmodule PanWeb.Surface.Admin.DataBlock do
  use Surface.Component
  alias PanWeb.Surface.Admin.ShowPresenter
  require Integer

  prop(record, :map, required: true)
  prop(columns, :list, required: true)

  def titelize(string) do
    string
    |> String.replace("_", " ")
    |> String.capitalize()
  end

  def render(assigns) do
    ~H"""
    <div class="mt-4 grid"
         style="grid-template-columns: max-content 1fr;">
      <For each={{ {column, index} <- @columns |> Enum.with_index() }}>
        <div class={{ "px-2 py-0.5 text-gray-darker italic text-right",
                      "bg-white": Integer.is_even(index),
                      "bg-gray-lightest": Integer.is_odd(index),
                      "border-t-2 border-gray-lighter": index > 0 }}>
          {{ titelize(column.field) }}
        </div>
        <div class={{ "w-full pl-4 pr-2 py-0.5",
                      "bg-white": Integer.is_even(index),
                      "bg-gray-lightest": Integer.is_odd(index),
                      "border-t-2 border-gray-lighter": index > 0 }}>
          <ShowPresenter record={{ @record }}
                          field={{ column.field }}
                          type={{ column.type }} />
        </div>
      </For>
    </div>
    """
  end
end
