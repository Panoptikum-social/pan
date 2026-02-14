defmodule PanWeb.Surface.Submit do
  use PanWeb, :html

  attr :label, :string, required: false, default: "Submit"
  attr :class, :string, required: false, default: "btn btn-info"

  def render(assigns) do
    ~H"""
    <.button type="submit" class={@class}>
      {@label}
    </.button>
    """
  end
end
