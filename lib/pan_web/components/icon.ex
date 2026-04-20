defmodule PanWeb.Component.Icon do
  use PanWeb, :html
  import PanWeb.ViewHelpers, only: [icon: 2]

  attr :name, :string, required: true
  attr :class, :string, default: ""
  attr :spaced, :boolean, default: false

  def render(assigns) do
    ~H"""
    {icon(@name, class: "h-5 w-5 inline align-text-bottom #{@class}")}
    <%= if @spaced do %>&nbsp;<% end %>
    """
  end
end
