defmodule PanWeb.Component.MarkdownField do
  use PanWeb, :html

  attr :myfield, :any, required: true
  attr :disabled, :boolean, default: false

  def render(assigns) do
    ~H"""
    <div phx-hook="MarkdownField"
         id="markdown-field-container"
         data-disabled={@disabled}
         phx-update="ignore">
      <.input type="textarea"
              field={@myfield}
              id="simplemde"
              rows="5"
              class="w-full input"
              label="Long description"
              disabled={@disabled} />

      <link rel="stylesheet" href="/simplemde/simplemde.min.css">
    </div>
    """
  end
end
