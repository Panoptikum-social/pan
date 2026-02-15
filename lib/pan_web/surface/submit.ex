defmodule PanWeb.Surface.Submit do
  use PanWeb, :html

  attr :label, :string, default: "Submit"
  attr :class, :string, default: "btn btn-info"

  def render(assigns) do
    ~H"""
    <.button type="submit" class={@class}>
      {@label}
    </.button>
    """
  end
end
