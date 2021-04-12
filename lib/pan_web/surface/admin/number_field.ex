defmodule PanWeb.Surface.Admin.NumberField do
  use Surface.Component
  alias Surface.Components.Form
  alias PanWeb.Surface.Admin.ErrorTag

  prop(name, :string, required: true)
  prop(redact, :boolean, required: false, default: false)

  def render(assigns) do
    ~H"""
    <Form.Field name={{ @name }} class="my-2 flex items-center justify-end">
      <Form.Label class="italic text-right"/>
      <div class="flex flex-col items-center">
        <Form.NumberInput :if={{ !@redact }}
                          class={{ "ml-3 w-32 text-right px-2 py-0 rounded-none
                                   disabled:bg-gray-lighter",
                                   "cursor-not-allowed": @name == "id" }}
                          opts= {{ disabled: @name == :id }} />
        <Form.TextInput :if={{ @redact }}
                        value="** redacted **"
                        class="ml-3 w-32 px-2 py-0 rounded-none"
                        opts={{ disabled: true }} />
        <ErrorTag />
      </div>
    </Form.Field>
    """
  end
end
