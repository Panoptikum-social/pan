defmodule PanWeb.Surface.Admin.ErrorTag do
  use Surface.Component
  alias Surface.Components.Form

  def render(assigns) do
    ~F"""
    <Form.ErrorTag class="inline-block px-2 mt-2 text-grapefruit bg-grapefruit border border-dotted border-grapefruit" />
    """
  end
end
