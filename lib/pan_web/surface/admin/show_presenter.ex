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
          :boolean ->
            case data do
              true -> "✅"
              false -> "❌"
            end

          :string ->
            cond do
              String.starts_with?(data, ["http://", "https://"]) ->
                raw("<a class=\"text-link hover:text-link-dark\" href=\"#{data}\">#{data}</a>")

              true ->
                data
            end

          _ ->
            data
        end
      end
    end
  end

  def render(assigns) do
    ~H"""
    {{ present(@presenter, @record, @field, @type) }}
    """
  end
end
