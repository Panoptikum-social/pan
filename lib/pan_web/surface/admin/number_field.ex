defmodule PanWeb.Surface.Admin.NumberField do
  use Surface.Component
  alias Surface.Components.Form

  prop(name, :string, required: true)

  def render(assigns) do
    ~H"""
    <Form.Field name={{ @name |> String.to_atom() }} class="my-3 flex justify-end items-center">
      <Form.Label class="italic"/>
      <Form.NumberInput class="ml-3 w-32 text-right px-2 py-0 rounded-none" />
      <Form.ErrorTag />
    </Form.Field>
    """
  end
end
