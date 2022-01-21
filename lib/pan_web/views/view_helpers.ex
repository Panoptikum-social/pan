defmodule PanWeb.ViewHelpers do
  alias Phoenix.HTML
  alias PanWeb.Live.Icon

  def icon(name), do: icon(name, class: "h-5 w-5 inline")

  def icon(name, class: class) do
    Icon.to_string(name, class: class)
    |> HTML.raw()
  end

  def nav_icon(name), do: icon(name, class: "h-5 w-5 inline")

  def btn_cycle(counter) do
    Enum.at(
      [
        "btn-default",
        "btn-gray-lighter",
        "btn-gray",
        "btn-gray-darker",
        "btn-success",
        "btn-info",
        "btn-primary",
        "btn-blue-jeans",
        "btn-lavender",
        "btn-pink-rose",
        "btn-danger",
        "btn-bittersweet",
        "btn-warning"
      ],
      rem(counter, 13)
    )
  end

  def truncate_string(nil, _len), do: ""

  def truncate_string(string, len) do
    if String.length(string) > len - 3 do
      String.slice(string, 0, len - 3) <> "..."
    else
      string
    end
  end

  def my_safe_to_string({:safe, string}), do: HTML.safe_to_string({:safe, string})
  def my_safe_to_string(string), do: string
end
