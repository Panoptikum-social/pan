defmodule PanWeb.Surface.Submit do
  use Surface.Component
  alias Surface.Components.Form

  prop label, :string, required: false, default: "Submit"

  def render(assigns) do
    ~H"""
    <Form.Submit label={{ @label}}
            class="my-4 py-2 px-4 rounded-lg font-medium text-white bg-aqua hover:bg-aqua-light" />
    """
  end
end
