defmodule PanWeb.Surface.PasswordField do
  use Surface.Component
  use PanWeb, :html
  alias Surface.Components.Form

  prop(name, :atom, required: true)
  prop(value, :string, required: true)

  def render(assigns) do
    ~F"""
    <Form.Field {=@name} class="my-4">
      <Form.Label class="block font-medium text-gray-darker"/>
      <Form.PasswordInput class="w-full"
                          {=@value} />
      <Form.ErrorTag />
    </Form.Field>

    """
  end
end
