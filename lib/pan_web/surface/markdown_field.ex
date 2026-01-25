defmodule PanWeb.Surface.MarkdownField do
  use Surface.Component
  use PanWeb, :html

  prop(myfield, :any, required: true)
  prop(disabled, :boolean, default: false)

  def render(assigns) do
    ~F"""
    <div :hook="MarkdownField"
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
