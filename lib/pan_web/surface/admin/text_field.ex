defmodule PanWeb.Surface.Admin.TextField do
  use Surface.Component
  alias Surface.Components.Form
  alias PanWeb.Surface.Admin.ErrorTag

  prop(name, :atom, required: true)
  prop(redact, :boolean, required: false, default: false)

  def render(assigns) do
    ~F"""
    <Form.Field name={@name} class="my-2">
      <Form.Label class="italic"/>
      <Form.TextInput :if={!@redact}
                      class="w-full px-2 py-0 rounded-none" />
      <Form.TextInput :if={@redact}
                      value="** redacted **"
                      class="w-full px-2 py-0 rounded-none"
                      opts={disabled: true} />
     <ErrorTag />
    </Form.Field>
    """
  end
end
