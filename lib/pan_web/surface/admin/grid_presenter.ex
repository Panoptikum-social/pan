defmodule PanWeb.Surface.Admin.GridPresenter do
  use Surface.Component
  require Integer

  prop presenter, :fun, required: false
  prop record, :any, required: true
  prop field, :string, required: true
  prop type, :atom, required: false, values: [:string, :integer], default: :string
  prop index, :integer, required: false, default: 0
  prop width, :string, required: false, default: ""

  def present(presenter, record, field, format) do
    if presenter do
      presenter.(record)
    else
      data = Map.get(record, String.to_atom(field))

      case format do
        :boolean ->
          case data do
            true -> "✔️"
            false -> "❌"
            _ -> "{}"
          end

        _ ->
          data
      end
    end
  end

  def render(assigns) do
    ~H"""
    <div class={{ "bg-white text-very-gray-darker px-1 grid content-center",
                  @width,
                  "text-right whitespace-nowrap": (@type == :integer),
                  "text-right whitespace-nowrap": (@type == :boolean),
                  "text-center whitespace-nowrap": (@type == :datetime),
                  "text-left": (@type == :string),
                  "bg-gray-lighter": Integer.is_odd(@index) }}
                 x-data="{ detailsOpen: false }">
      <div @click="detailsOpen = !detailsOpen
                   $nextTick(() => $refs.detailsCloseButton.focus())"
           class="truncate">
        {{ present(@presenter, @record, @field, @type) }}
      </div>
      <div x-show="detailsOpen"
           class="absolute inset-52 mx-auto items-center bg-gray-lightest
                  border border-gray p-4">
        <h1 class="text-2xl">Details</h1>
        <p class="mt-6">
          {{ present(@presenter, @record, @field, @type)}}
        </p>
        <button @click="detailsOpen = false"
                class="absolute bottom-4 left-4 bg-info hover:bg-info-light text-white p-2 rounded mt-6
                       focus:ring-2 focus:ring-info-light"
                x-ref="detailsCloseButton">
          Close
        </button>
      </div>
    </div>
    """
  end
end
