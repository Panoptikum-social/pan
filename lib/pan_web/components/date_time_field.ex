defmodule PanWeb.Component.DateTimeField do
  use PanWeb, :html

  attr :name, :string, required: true

  def render(assigns) do
    ~H"""
    <.input type="datetime-local" name={@name} />
    """
  end
end
