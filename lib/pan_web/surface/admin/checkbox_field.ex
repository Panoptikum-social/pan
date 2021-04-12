defmodule PanWeb.Surface.Admin.CheckBoxField do
  use Surface.Component
  alias Surface.Components.Form
  alias PanWeb.Surface.Admin.ErrorTag

  prop(name, :string, required: true)
  prop(label, :string, required: true)
  prop(redact, :boolean, required: false, default: false)

  def render(assigns) do
    ~H"""
    <Form.Field name={{ @name }}
               class="my-2 flex items-center">
      <Form.Checkbox :if={{ !@redact }} />
      <div :if={{ @redact }}>**</div>
      <Form.Label class="italic pl-2">
        {{ @label }}
      </Form.Label>
      <div :if={{ @redact }} class="pl-2"> (redacted)</div>
      <ErrorTag />
    </Form.Field>
    """
  end
end
