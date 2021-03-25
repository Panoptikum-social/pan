defmodule PanWeb.Surface.Admin.StringBlock do
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
    <div class="my-8 grid grid-cols-5">
      <For each={{ {column, index} <- @columns |> Enum.with_index() }}>
        <div class={{"p-1 text-gray font-semibold text-right col-span-1",
                     "odd:bg-gray-lightest": Integer.is_even(index)}}>
          {{ titelize(column.field) }}:
        </div>
        <div class={{"p-1 col-span-4",
                     "odd:bg-gray-lightest": Integer.is_even(index)}}>
           <ShowPresenter record={{ @record }}
                          field={{ column.field }}
                          type={{ column.type }} />
        </div>
      </For>
    </div>
    """
  end
end
