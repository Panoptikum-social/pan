defmodule PanWeb.Surface.Admin.TableData do
  use Surface.Component

  prop presenter, :fun, required: false
  prop record, :any, required: true
  prop field, :string
  prop type, :atom, values: [:string, :integer], default: :string

  def present(presenter, record, field, type) do
    if presenter do
      presenter.(record)
    else
      Map.get(record, String.to_atom(field))
    end
  end

  def render(assigns) do
    ~H"""
    <td class={{ "border border-light-gray text-very-dark-gray p-1",
                 "text-right whitespace-nowrap": (@type == :integer),
                 "text-center whitespace-nowrap": (@type == :datetime),
                 "text-left truncate max-w-sm": (@type == :string) }}
                 x-data="{ detailsOpen: false }">
      <span @click="detailsOpen = !detailsOpen
                    $nextTick(() => $refs.detailsCloseButton.focus())">
        {{ present(@presenter, @record, @field, @type) }}
      </span>
      <div x-show="detailsOpen"
           class="absolute inset-52 mx-auto items-center bg-very-light-gray
                  border border-medium-gray p-4">
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
    </td>
    """
  end
end
