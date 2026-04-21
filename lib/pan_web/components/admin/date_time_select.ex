defmodule PanWeb.Components.Admin.DateTimeSelect do
  use PanWeb, :html
  use Phoenix.Component

  attr :name, :string, required: true
  attr :value, :any, default: nil
  attr :redact, :boolean, required: false, default: false

  def render(assigns) do
    ~H"""
    <%= if @redact do %>
      <.input value="** redacted **" readonly />
    <% else %>
      <.input type="datetime-local" name={@name} value={@value} />
    <% end %>
    """
  end
end
