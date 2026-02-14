defmodule PanWeb.Surface.CheckBoxField do
  use PanWeb, :html

  attr :name, :atom, required: true
  attr :label, :string, required: true

  def render(assigns) do
    ~H"""
    <.input type="checkbox" name={@name} label={@label} />
    """
  end
end
