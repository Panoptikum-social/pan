defmodule PanWeb.Surface.Admin.TextField do
  use Surface.Component
  alias Surface.Components.Form

  prop(name, :string, required: true)

  def render(assigns) do
    ~H"""
    <Form.Field name={{ @name |> String.to_atom() }} class="my-2 flex flex-col sm:flex-row justify-end sm:items-center">
      <Form.Label class="block italic w-40 sm:text-right flex-shrink-0"/>
      <Form.TextInput class="w-full ml-3 px-2 py-0 rounded-none" />
      <Form.ErrorTag />
    </Form.Field>
    """
  end
end
