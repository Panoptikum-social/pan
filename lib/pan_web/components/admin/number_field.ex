defmodule PanWeb.Components.Admin.NumberField do
  use PanWeb, :html
  use Phoenix.Component

  attr :name, :string, required: true
  attr :redact, :boolean, required: false, default: false

  def render(assigns) do
    ~H"""
    <%= if @redact do %>
      <.input value="** redacted **" readonly />
    <% else %>
      <.input
        type="number"
        name={@name}
        readonly={@name == :id}
      />
    <% end %>
    """
  end
end
