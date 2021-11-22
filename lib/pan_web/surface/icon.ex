defmodule PanWeb.Surface.Icon do
  use Surface.Component
  import PanWeb.ViewHelpers

  prop(name, :string, required: true)
  prop(spaced, :boolean, required: false, default: false)

  def render(assigns) do
    ~F"""
    {icon(@name, class: "h-5 w-5 inline align-text-bottom")}{#if @spaced}&nbsp;{/if}
    """
  end
end
