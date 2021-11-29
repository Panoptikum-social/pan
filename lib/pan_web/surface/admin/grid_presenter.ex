defmodule PanWeb.Surface.Admin.GridPresenter do
  use Surface.Component
  require Integer

  prop(presenter, :fun, required: false)
  prop(model, :module, required: true)
  prop(record, :any, required: true)
  prop(field, :string, required: true)
  prop(type, :atom, required: false, values: [:string, :integer], default: :string)
  prop(index, :integer, required: false, default: 0)
  prop(width, :string, required: false, default: "")
  prop(dye, :boolean, required: false, default: false)

  def present(presenter, record, field, format) do
    if presenter do
      presenter.(record)
    else
      data = Map.get(record, field)

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
    ~F"""
    <div :if={@model.__schema__(:redact_fields) |> Enum.member?(@field) |> Kernel.not}
         class={"text-very-gray-darker px-1 grid content-center truncate",
                @width,
                "text-right whitespace-nowrap": (@type in [:integer, :id]),
                "text-right whitespace-nowrap": (@type == :boolean),
                "text-center whitespace-nowrap": (@type in [:datetime, :naive_datetime]),
                "text-left": (@type == :string),
                "bg-gray-lighter": Integer.is_odd(@index) && !@dye,
                "bg-white": Integer.is_even(@index) && !@dye,
                "bg-sunflower-lighter": @dye}
                x-data="{ detailsOpen: false }">
      {present(@presenter, @record, @field, @type)}
    </div>

    <div :if={@model.__schema__(:redact_fields) |> Enum.member?(@field)}
         class={"bg-white text-very-gray-darker px-1 grid content-center text-center whitespace-nowrap",
                @width,
                "bg-gray-lighter": Integer.is_odd(@index)}
                x-data="{ detailsOpen: false }">
      ** redacted **
    </div>
    """
  end
end
