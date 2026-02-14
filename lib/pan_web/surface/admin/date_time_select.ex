defmodule PanWeb.Surface.Admin.DateTimeSelect do
  use PanWeb, :html

  attr :name, :string, required: true
  attr :redact, :boolean, required: false, default: false

  def render(assigns) do
    ~H"""
    <%= if @redact do %>
      <.input value="** redacted **" readonly />
    <% else %>
      <.input type="datetime-local" name={@name} />
    <% end %>
    """
  end
end
