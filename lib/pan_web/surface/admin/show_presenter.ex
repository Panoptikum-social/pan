defmodule PanWeb.Surface.Admin.ShowPresenter do
  use Surface.Component
  require Integer

  prop(presenter, :fun, required: false)
  prop(record, :any, required: true)
  prop(field, :string, required: true)
  prop(type, :atom, required: false, values: [:string, :integer], default: :string)
  prop(index, :integer, required: false, default: 0)
  prop(width, :string, required: false, default: "")

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
            _ -> "∅"
          end

        :string ->
          cond do
            data == nil ->
              "∅"

            String.starts_with?(data, ["http://", "https://"]) ->
              raw("<a class=\"text-link hover:text-link-dark\" href=\"#{data}\">#{data}</a>")

            true ->
              data
          end

        :datetime ->
          data

        :naive_datetime ->
          data

        :integer ->
          data

        :float ->
          data

        :"Ecto.UUID" ->
          data

        type ->
          "unknown data type: #{type}"
      end
    end
  end

  def render(assigns) do
    ~H"""
    <div class="truncate">
      {{ present(@presenter, @record, @field, @type) }}
    </div>
    """
  end
end
