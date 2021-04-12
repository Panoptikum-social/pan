defmodule PanWeb.Surface.Admin.TextAreaField do
  use Surface.Component
  alias Surface.Components.Form
  alias PanWeb.Surface.Admin.ErrorTag

  prop(name, :string, required: true)
  prop(redact, :boolean, required: false, default: false)

  def render(assigns) do
    ~H"""
    <Form.Field name={{ @name }} class="my-2">
      <Form.Label class="italic"/>
      <Form.TextArea :if={{ !@redact }}
                     class="w-full px-2 py-0 rounded-none"
                     rows=5 />
      <Form.TextInput :if={{ @redact }}
                      value="** redacted **"
                      class="w-full px-2 py-0 rounded-none"
                      opts={{ disabled: true }} />
      <ErrorTag />
    </Form.Field>
    """
  end
end
