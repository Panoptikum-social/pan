defmodule PanWeb.Surface.Admin.ErrorTag do
  use Surface.Component
  alias Surface.Components.Form

  def render(assigns) do
    ~H"""
    <Form.ErrorTag class="inline-block px-2 mt-2
                          text-grapefruit bg-grapefruit bg-opacity-20
                          border border-dotted border-grapefruit" />
    """
  end
end
