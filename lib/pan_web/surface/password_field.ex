defmodule PanWeb.Surface.PasswordField do
  use PanWeb, :html

  attr :name, :atom, required: true
  attr :value, :string, required: true

  def render(assigns) do
    ~H"""
    <.input tpye = "password" name={@name} value={@value} />
    """
  end
end
