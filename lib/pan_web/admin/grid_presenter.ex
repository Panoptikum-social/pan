defmodule PanWeb.Admin.GridPresenter do
  use PanWeb, :html
  require Integer

  def present(presenter, record, field, format) do
    if presenter do
      presenter.(record)
    else
      data = Map.get(record, field)

      case format do
        :boolean ->
          case data do
            true -> "☒"
            false -> "☐"
            _ -> "∅"
          end

        _ ->
          data
      end
    end
  end

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
           "text-very-gray-darker px-1 grid content-center truncate",
           @width,
           if(@type in [:integer, :id, :boolean], do: "text-right whitespace-nowrap"),
           if(@type in [:datetime, :naive_datetime], do: "text-center whitespace-nowrap"),
           if(@type == :string, do: "text-left"),
           if(Integer.is_odd(@index) && !@dye, do: "bg-gray-lighter"),
           if(Integer.is_even(@index) && !@dye, do: "bg-white"),
           if(@dye, do: "bg-sunflower-lighter")
         ]}
         x-data="{ detailsOpen: false }">
      {present(@presenter, @record, @field, @type)}
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
