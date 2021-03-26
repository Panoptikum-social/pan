defmodule PanWeb.Surface.Admin.CheckBoxField do
  use Surface.Component
  alias Surface.Components.Form

  prop(name, :string, required: true)
  prop(label, :string, required: true)

  def render(assigns) do
    ~H"""
    <Form.Field name={{ @name |> String.to_atom() }}
                class="my-2 flex items-center">
      <Form.Checkbox />
      <Form.Label class="italic pl-2">
        {{ @label }}
      </Form.Label>
      <Form.ErrorTag />
    </Form.Field>
    """
  end
end
