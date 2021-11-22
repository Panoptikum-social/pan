defmodule PanWeb.Surface.Admin.ShowPresenter do
  use Surface.Component
  require Integer

  prop(presenter, :fun, required: false)
  prop(record, :any, required: true)
  prop(field, :string, required: true)
  prop(type, :atom, required: false, values: [:string, :integer], default: :string)
  prop(index, :integer, required: false, default: 0)
  prop(width, :string, required: false, default: "")
  prop(redact, :boolean, required: false, default: false)

  def present(presenter, record, field, format, redact) do
    cond do
      redact ->
        "** redacted **"

      presenter ->
        presenter.(record)

      true ->
        data = Map.get(record, field)

        if data == nil do
          "∅"
        else
          case format do
            :boolean ->
              if data, do: "✅", else: "❌"

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

            :datetime ->
              raw(
                "<span class=\"pr-2\">📅</span>" <>
                  (data |> DateTime.to_date |> Date.to_string) <>
                  "<span class=\"pl-4 pr-2\">🕒</span>" <>
                  (data |> DateTime.to_time |> Time.to_string)
              )

            :naive_datetime ->
              raw(
                "<span class=\"pr-2\">📅</span>" <>
                  (data |> NaiveDateTime.to_date |> Date.to_string) <>
                  "<span class=\"pl-4 pr-2\">🕒</span>" <>
                  (data |> NaiveDateTime.to_time |> Time.to_string)
              )

            _ ->
              data
          end
        end
    end
  end

  def render(assigns) do
    ~F"""
    <div class={"text-right font-mono": @type in [:integer, :float, :datetime, :naive_datetime],
                  "text-center": @type == :boolean}>
      {present @presenter, @record, @field, @type, @redact}
    </div>
    """
  end
end
