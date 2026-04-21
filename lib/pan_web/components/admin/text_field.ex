defmodule PanWeb.Components.Admin.TextField do
  use PanWeb, :html
  use Phoenix.Component

  attr :name, :atom, required: true
  attr :value, :any, default: nil
  attr :redact, :boolean, required: false, default: false

  def render(assigns) do
    ~H"""
    <%= if @redact do %>
      <.input value="** redacted **" readonly />
    <% else %>
      <.input name={@name} value={@value} />
    <% end %>
    """
  end
end
