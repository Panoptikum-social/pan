defmodule PanWeb.Surface.NumberField do
  use PanWeb, :html

  attr :name, :string, required: true

  def render(assigns) do
    ~H"""
      <.input type="number" name={@name} />
    """
  end
end
