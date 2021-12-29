defmodule PanWeb.Surface.Icon do
  use Surface.Component
  import PanWeb.ViewHelpers, only: [icon: 2]

  prop(name, :string, required: true)
  prop(class, :css_class, required: false, default: "")
  prop(spaced, :boolean, required: false, default: false)

  def render(assigns) do
    ~F"""
    {icon(@name, class: "h-5 w-5 inline align-text-bottom #{@class}")}{#if @spaced}&nbsp;{/if}
    """
  end
end
