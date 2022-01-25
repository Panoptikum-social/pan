defmodule PanWeb.Surface.TextField do
  use Surface.Component
  alias Surface.Components.Form
  alias PanWeb.Surface.ErrorTag

  prop(name, :atom, required: true)

  def render(assigns) do
    ~F"""
    <Form.Field {=@name} class="my-4">
      <Form.Label class="block font-medium text-gray-darker"/>
      <Form.TextInput class="w-full" />
      <ErrorTag />
    </Form.Field>
    """
  end
end
