defmodule PanWeb.Surface.Icon do
  use Surface.Component
  import PanWeb.ViewHelpers

  prop(name, :string, required: true)
  prop(spaced, :boolean, required: false, default: false)

  def render(assigns) do
    ~H"""
    {{ icon(@name, class: "h-5 w-5 align-text-bottom") }}<If condition={{ @spaced }}>&nbsp;</If>
    """
  end
end
