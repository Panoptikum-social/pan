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

  def present(_presenter, _record, _field, _format, true = _redact), do: "** redacted **"
  def present(nil, record, field, format, false), do: present(record, field, format)
  def present(presenter, record, _field, _format, false), do: presenter.(record)

  def present(record, field, format) do
    if data = Map.get(record, field), do: present(format, data), else: "∅"
  end
  def present(:boolean, nil), do: "❌"
  def present(:boolean, _data), do: "✅"

  def present(:string, data) do
    if String.starts_with?(data, ["http://", "https://"]) do
      "<a class=\"text-link hover:text-link-dark\" href=\"#{data}\">#{data}</a>"
      |> raw
    else
      data
    end
  end

  def present(:float, data) do
    rounded = Float.round(data, 2)

    if rounded == data do
      data
    else
      "~ " <> Float.to_string(rounded)
    end
  end

  def present(:integer, data), do: raw(Integer.to_string(data) <> "&nbsp;&nbsp;&nbsp;")

  def present(:datetime, data) do
    raw(
      "<span class=\"pr-2\">📅</span>" <>
        (data |> DateTime.to_date() |> Date.to_string()) <>
        "<span class=\"pl-4 pr-2\">🕒</span>" <>
        (data |> DateTime.to_time() |> Time.to_string())
    )
  end

  def present(:naive_datetime, data) do
    raw(
      "<span class=\"pr-2\">📅</span>" <>
        (data |> NaiveDateTime.to_date() |> Date.to_string()) <>
        "<span class=\"pl-4 pr-2\">🕒</span>" <>
        (data |> NaiveDateTime.to_time() |> Time.to_string())
    )
  end

  def present(_unknown_format, data), do: data

  def render(assigns) do
    ~F"""
    <div class={"text-right font-mono": @type in [:integer, :float, :datetime, :naive_datetime],
                "text-center": @type == :boolean}>
      {present @presenter, @record, @field, @type, @redact}
    </div>
    """
  end
end
