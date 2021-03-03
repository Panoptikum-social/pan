defmodule PanWeb.Surface.Panel do
  use Surface.Component

  prop heading, :string, required: true
  prop purpose, :string, required: false, default: "default"
  prop heading_right, :string, required: false
  prop target, :fun, required: false

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

  def render(assigns) do
    ~H"""
    <div aria-label="panel" class="border rounded-xl my-4 w-full">
      <div aria-label="panel heading" class={{ "p-3 rounded-t-xl", heading_color_classes(@purpose) }}>
        <If condition={{ !@target }}>
          {{@heading}}
        </If>
        <a :if={{ @target }} href={{ @target }} class="hover:text-gray-200">
          {{ @heading }}
        </a>
        <a :if={{ @target }} href={{ @target }} class="float-right hover:text-gray-200">
          {{ @heading_right }}
        </a>

      </div>

      <div class="rounded-b-xl">
        <slot>No content defined!</slot>
      </div>
    </div>
    """
  end
end
