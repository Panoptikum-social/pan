defmodule PanWeb.Surface.PasswordField do
  use Surface.Component
  alias Surface.Components.Form
  alias PanWeb.Surface.ErrorTag

  prop(name, :atom, required: true)
  prop(value, :string, required: true)

  def render(assigns) do
    ~F"""
    <Form.Field {=@name} class="my-4">
      <Form.Label class="block font-medium text-gray-darker"/>
      <Form.PasswordInput class="w-full"
                          {=@value} />
      <ErrorTag />
    </Form.Field>
    """
  end
end
