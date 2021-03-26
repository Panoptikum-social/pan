defmodule PanWeb.Surface.Admin.DataBlock do
  use Surface.Component
  alias PanWeb.Surface.Admin.ShowPresenter
  require Integer

  prop record, :map, required: true
  prop columns, :list, required: true

  def titelize(string) do
    string
    |> String.replace("_", " ")
    |> String.capitalize()
  end

  def render(assigns) do
    ~H"""
    <div class="mt-4 grid"
         style="grid-template-columns: repeat(2, minmax(0, max-content));">
      <For each={{ {column, index} <- @columns |> Enum.with_index() }}>
        <div class={{ "px-2 text-gray-darker font-mono text-right",
                      "bg-gray-lightest": Integer.is_even(index) }}>
          {{ titelize(column.field) }}
        </div>
        <div class={{ "px-2",
                      "bg-gray-lightest": Integer.is_even(index) }}>
          <ShowPresenter record={{ @record }}
                          field={{ column.field }}
                          type={{ column.type }} />
        </div>
      </For>
    </div>
    """
  end
end
