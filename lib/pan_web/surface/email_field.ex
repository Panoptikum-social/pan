defmodule PanWeb.Surface.EmailField do
  use Surface.Component
  alias Surface.Components.Form
  alias PanWeb.Surface.ErrorTag

  prop(name, :atom, required: true)

  def render(assigns) do
    ~F"""
    <Form.Field {=@name} class="my-4">
      <Form.Label class="block font-medium text-gray-darker"/>
      <Form.EmailInput class="w-full" />
      <ErrorTag />
    </Form.Field>
    """
  end
end
