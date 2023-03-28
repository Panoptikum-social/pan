defmodule PanWeb.Surface.Admin.DateTimeSelect do
  use Surface.Component
  alias Surface.Components.Form
  alias Surface.Components.Form.DateTimeLocalInput
  alias PanWeb.Surface.Admin.ErrorTag

  prop(name, :string, required: true)
  prop(redact, :boolean, required: false, default: false)

  def render(assigns) do
    ~F"""
    <Form.Field name={@name} class={"my-2 flex items-center", "justify-end": !@redact}>
      <Form.Label class="italic"/>
      <div class="ml-3 flex flex-col items-start">
        <DateTimeLocalInput :if={!@redact} />
        <Form.TextInput :if={@redact}
                        value="** redacted **"
                        class="w-32 px-2 py-0 rounded-none"
                        opts={disabled: true} />
        <ErrorTag/>
      </div>
    </Form.Field>
    """
  end
end
