defmodule PanWeb.Surface.Admin.TextField do
  use PanWeb, :html

  attr :name, :atom, required: true
  attr :redact, :boolean, required: false, default: false

  def render(assigns) do
    ~H"""
    <%= if @redact do %>
      <.input value="** redacted **" readonly />
    <% else %>
      <.input name={@name} />
    <% end %>
    """
  end
end
