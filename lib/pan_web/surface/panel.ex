defmodule PanWeb.Surface.Panel do
  use Surface.Component

  prop heading, :string, required: true
  prop purpose, :string, required: false, default: "default"
  prop heading_right, :string
  prop target, :fun

  slot default

  def heading_color_classes(purpose) do
    case purpose do
      "podcast" -> "bg-blue-400 text-white"
      "popular" -> "bg-teal-500 text-white"
      "like" -> "bg-rose-600 text-white"
      "episode" -> "bg-amber-400 text-white"
      "recommendation" -> "bg-lime-500 text-white"
      _ -> "bg-white"
    end
  end
end
