defmodule PanWeb.Admin.GridPresenterWithDetails do
  use PanWeb, :html
  require Integer

  def present(presenter, record, _field, _format) when is_function(presenter), do: presenter.(record)
  def present(_presenter, record, field, :boolean), do: format_boolean(Map.get(record, field))
  def present(_presenter, record, field, _format), do: Map.get(record, field)

  defp format_boolean(true), do: "✔️"
  defp format_boolean(false), do: "❌"
  defp format_boolean(_), do: "{}"

  attr :presenter, :any, default: nil
  attr :model, :any, required: true
  attr :record, :any, required: true
  attr :field, :string, required: true
  attr :type, :atom, default: :string
  attr :index, :integer, default: 0
  attr :width, :string, default: ""
  attr :dye, :boolean, default: false

  def render(assigns) do
    ~H"""
    <div :if={@model.__schema__(:redact_fields) |> Enum.member?(@field) |> Kernel.not}
         class={[
           "text-very-gray-darker px-1 grid content-center",
           @width,
           if(@type in [:integer, :id, :boolean], do: "text-right whitespace-nowrap"),
           if(@type in [:datetime, :naive_datetime], do: "text-center whitespace-nowrap"),
           if(@type == :string, do: "text-left"),
           if(Integer.is_odd(@index) && !@dye, do: "bg-gray-lighter"),
           if(Integer.is_even(@index) && !@dye, do: "bg-white"),
           if(@dye, do: "bg-sunflower-lighter")
         ]}
         x-data="{ detailsOpen: false }">
      <div @click="detailsOpen = !detailsOpen
                   $nextTick(() => $refs.detailsCloseButton.focus())"
           class="truncate">
        {present(@presenter, @record, @field, @type)}
      </div>
      <div x-show="detailsOpen"
           class="absolute inset-52 mx-auto items-center bg-gray-lightest
                  border border-gray p-4">
        <h1 class="text-3xl">Details</h1>
        <p class="mt-6">
          {present(@presenter, @record, @field, @type)}
        </p>
        <button @click="detailsOpen = false"
                class="absolute bottom-4 left-4 bg-info hover:bg-info-light text-white p-2 rounded mt-6
                       focus:ring-2 focus:ring-info-light"
                x-ref="detailsCloseButton">
          Close
        </button>
      </div>
    </div>

    <div :if={@model.__schema__(:redact_fields) |> Enum.member?(@field)}
         class={[
           "bg-white text-very-gray-darker px-1 grid content-center text-center whitespace-nowrap",
           @width,
           if(Integer.is_odd(@index), do: "bg-gray-lighter")
         ]}
         x-data="{ detailsOpen: false }">
      ** redacted **
    </div>
    """
  end
end
