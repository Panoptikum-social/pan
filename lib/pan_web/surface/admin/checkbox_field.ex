defmodule PanWeb.Surface.Admin.CheckBoxField do
  use PanWeb, :html

  attr :name, :string, required: true
  attr :label, :string, required: true
  attr :redact, :boolean, required: false, default: false

  def render(assigns) do
    ~H"""
    <%= if @redact do %>
      <div>**</div>
      <div class="pl-2">(redacted)</div>
      {@label}
      <.error :for={msg <- @errors}>{msg}</.error>
    <% else %>
      <.input type="checkbox" name={@name} label={@label} />
    <% end %>
    """
  end
end
