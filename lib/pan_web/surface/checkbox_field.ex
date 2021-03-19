defmodule PanWeb.Surface.CheckBoxField do
  use Surface.Component
  alias Surface.Components.Form

  prop name, :string, required: true
  prop label, :string, required: true

  def render(assigns) do
    ~H"""
    <Form.Field name={{ @name |> String.to_atom() }}
                class="my-4 flex items-center">
      <Form.Checkbox />
      <Form.Label class="font-medium text-gray-darker pl-4">
        {{ @label }}
      </Form.Label>
      <Form.ErrorTag />
    </Form.Field>
    """
  end
end
