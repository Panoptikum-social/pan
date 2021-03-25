defmodule PanWeb.Surface.Admin.DataBlock do
  use Surface.Component
  alias PanWeb.Surface.Admin.ShowPresenter

  prop record, :map, required: true
  prop columns, :list, required: true

  def titelize(string) do
    string
    |> String.replace("_", " ")
    |> String.capitalize()
  end

  def render(assigns) do
    ~H"""
    <div class="my-8 flex flex-row">
      <div class="flex flex-col text-gray font-semibold text-right">
        <div :for={{ column <- @columns }}
            class="odd:bg-gray-lightest p-1">
          {{ titelize(column.field) }}:
        </div>
      </div>

      <div class="flex flex-col">
        <div :for={{ column <- @columns }}
             class="odd:bg-gray-lightest p-1">
            <ShowPresenter record={{ @record }}
                          field={{ column.field }}
                          type={{ column.type }} />
        </div>
      </div>
    </div>
    """
  end
end
