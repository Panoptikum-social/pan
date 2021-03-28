defmodule PanWeb.Surface.Admin.TextField do
  use Surface.Component
  alias Surface.Components.Form

  prop(name, :string, required: true)

  def render(assigns) do
    ~H"""
    <Form.Field name={{ @name |> String.to_atom() }} class="my-2">
      <Form.Label class="italic"/>
      <Form.TextInput class="w-full px-2 py-0 rounded-none" />
      <Form.ErrorTag />
    </Form.Field>
    """
  end
end
