defmodule PanWeb.Surface.Admin.NumberField do
  use Surface.Component
  alias Surface.Components.Form
  alias PanWeb.Surface.Admin.ErrorTag

  prop(name, :string, required: true)

  def render(assigns) do
    ~H"""
    <Form.Field name={{ @name |> String.to_atom() }} class="my-2 flex items-center justify-end">
      <Form.Label class="italic text-right"/>
      <div class="flex flex-col items-center">
        <Form.NumberInput class="ml-3 w-32 text-right px-2 py-0 rounded-none" />
        <ErrorTag />
      </div>
    </Form.Field>
    """
  end
end
