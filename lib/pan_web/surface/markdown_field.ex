defmodule PanWeb.Surface.MarkdownField do
  use Surface.Component
  alias Surface.Components.Form

  prop(name, :atom, required: true)
  prop(disabled, :boolean, default: false)

  def render(assigns) do
    ~F"""
    <div :hook="MarkdownField"
         id="markdown-field-container"
         data-disabled={@disabled}
         phx-update="ignore">
      <Form.Field {=@name}>
        <Form.Label class="block font-medium text-gray-darker"/>
        <Form.TextArea id="simplemde"
                       rows={5}
                       class="w-full"
                       opts={[disabled: @disabled]} />
        <Form.ErrorTag />
      </Form.Field>

      <link rel="stylesheet" href="/simplemde/simplemde.min.css">
    </div>
    """
  end
end
