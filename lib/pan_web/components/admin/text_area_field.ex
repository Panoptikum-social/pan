defmodule PanWeb.Components.Admin.TextAreaField do
  use PanWeb, :html
  use Phoenix.Component

  attr :name, :string, required: true
  attr :value, :any, default: nil
  attr :label, :string, default: nil
  attr :redact, :boolean, default: false

  def render(assigns) do
    ~H"""
    <.input :if={!@redact}
            type="textarea"
            name={@name}
            value={@value}
            label={@label} />

    <.input :if={@redact}
            type="textarea"
            name={@name}
            label={@label}
            value="** redacted **"
            disabled />
    """
  end
end
