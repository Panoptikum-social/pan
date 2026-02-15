defmodule PanWeb.Components.Admin.TextAreaField do
  use PanWeb, :html
  use Phoenix.Component

  attr :name, :string, required: true
  attr :redact, :boolean, default: false

  def render(assigns) do
    ~H"""
    <.input :if={!@redact}
            type="textarea"
            name={@name}
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
