defmodule PanWeb.Surface.Admin.NumberField do
  use Surface.Component
  alias Surface.Components.Form

  prop(name, :string, required: true)

  def render(assigns) do
    ~H"""
    <Form.Field name={{ @name |> String.to_atom() }} class="my-2 flex items-center">
      <Form.Label class="italic w-40 text-right"/>
      <Form.NumberInput class="ml-3 w-32 text-right px-2 py-0 rounded-none" />
      <Form.ErrorTag />
    </Form.Field>
    """
  end
end
