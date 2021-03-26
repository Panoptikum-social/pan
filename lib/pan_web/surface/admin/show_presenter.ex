defmodule PanWeb.Surface.Admin.ShowPresenter do
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

      if data == nil do
        "∅"
      else
        case format do
          :boolean -> if data, do: "✅", else: "❌"

          :string ->
            if String.starts_with?(data, ["http://", "https://"]) do
              raw("<a class=\"text-link hover:text-link-dark\" href=\"#{data}\">#{data}</a>")
            else
              data
            end

          :float ->
            rounded = Float.round(data, 2)
            if rounded == data do
              data
            else
              "~ " <> Float.to_string(rounded)
            end

          :integer ->
              raw(Integer.to_string(data) <> "&nbsp;&nbsp;&nbsp;")

          _ ->
            data
        end
      end
    end
  end

  def render(assigns) do
    ~H"""
    <div class={{ "text-right font-mono": @type in [:integer, :float],
                  "text-center": @type == :boolean }}>
      {{ present(@presenter, @record, @field, @type) }}
    </div>
    """
  end
end
