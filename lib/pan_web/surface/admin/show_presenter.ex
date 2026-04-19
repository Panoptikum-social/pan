defmodule PanWeb.Surface.Admin.ShowPresenter do
  use PanWeb, :html
  require Integer

  attr :presenter, :any, default: nil
  attr :record, :any, required: true
  attr :field, :string, required: true
  attr :type, :atom, default: :string
  attr :index, :integer, default: 0
  attr :width, :string, default: ""
  attr :redact, :boolean, default: false

  def present(_presenter, _record, _field, _format, true = _redact), do: "** redacted **"
  def present(nil, record, field, format, false), do: present(record, field, format)
  def present(presenter, record, _field, _format, false), do: presenter.(record)

  def present(record, field, format) do
    if Map.get(record, field) == nil do
      "∅"
    else
      present(format, Map.get(record, field))
    end
  end

  def present(:boolean, true), do: "☒"
  def present(:boolean, false), do: "☐"

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
    ~H"""
    <div class={[
      @type in [:integer, :float, :datetime, :naive_datetime] && "text-right font-mono",
      @type == :boolean && "text-center"
    ]}>
      {present(@presenter, @record, @field, @type, @redact)}
    </div>
    """
  end
end
