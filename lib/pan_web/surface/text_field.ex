defmodule PanWeb.Surface.TextField do
  use PanWeb, :html

  attr :name, :atom, required: true

  def render(assigns) do
    ~H"""
    <.input type="text" name={@name} />
    """
  end
end
