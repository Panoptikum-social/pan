defmodule PanWeb.Surface.Admin.TextAreaField do
  use PanWeb, :html

  attr :name, :string, required: true
  attr :redact, :boolean, required: false, default: false

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
