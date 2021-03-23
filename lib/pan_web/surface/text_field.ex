defmodule PanWeb.Surface.TextField do
  use Surface.Component
  alias Surface.Components.Form

  prop(name, :string, required: true)

  def render(assigns) do
    ~H"""
    <Form.Field name={{ @name |> String.to_atom() }} class="my-4">
      <Form.Label class="block font-medium text-gray-darker"/>
      <Form.TextInput class="w-full" />
      <Form.ErrorTag />
    </Form.Field>
    """
  end
end
