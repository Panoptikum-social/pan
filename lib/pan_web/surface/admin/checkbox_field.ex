defmodule PanWeb.Surface.Admin.CheckBoxField do
  use Surface.Component
  alias Surface.Components.Form
  alias PanWeb.Surface.Admin.ErrorTag

  prop(name, :string, required: true)
  prop(label, :string, required: true)

  def render(assigns) do
    ~H"""
    <Form.Field name={{ @name }}
                class="my-2 flex items-center">
      <Form.Checkbox />
      <Form.Label class="italic pl-2">
        {{ @label }}
      </Form.Label>
      <ErrorTag />
    </Form.Field>
    """
  end
end
