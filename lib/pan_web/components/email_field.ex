defmodule PanWeb.Component.EmailField do
  use PanWeb, :html

  attr :name, :atom, required: true

  def render(assigns) do
    ~H"""
    <.input type="email" name={@name} />
    """
  end
end
