defmodule PanWeb.Components.Admin.DateTimeSelect do
  use PanWeb, :html
  use Phoenix.Component

  attr :name, :string, required: true
  attr :value, :any, default: nil
  attr :redact, :boolean, required: false, default: false

  def render(assigns) do
    ~H"""
    <%= if @redact do %>
      <.input label={Phoenix.Naming.humanize(@name)} value="** redacted **" readonly class="w-full input input-sm" />
    <% else %>
      <.input type="datetime-local" label={Phoenix.Naming.humanize(@name)} name={@name} value={@value} class="w-full input input-sm" />
    <% end %>
    """
  end
end
