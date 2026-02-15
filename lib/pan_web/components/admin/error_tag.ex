defmodule PanWeb.Components.Admin.ErrorTag do
  use PanWeb, :html

  def render(assigns) do
    ~H"""
    <.error :for={msg <- @errors}>{msg}</.error>
    """
  end
end
