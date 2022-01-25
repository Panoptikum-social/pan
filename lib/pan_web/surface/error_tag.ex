defmodule PanWeb.Surface.ErrorTag do
  use Surface.Component
  alias Surface.Components.Form.ErrorTag

  def render(assigns) do
    ~F"""
    <ErrorTag class="inline-block px-2 mt-2
                     text-grapefruit bg-grapefruit bg-opacity-20
                     border border-dotted border-grapefruit" />
    """
  end
end
