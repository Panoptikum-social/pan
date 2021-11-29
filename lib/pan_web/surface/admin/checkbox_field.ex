defmodule PanWeb.Surface.Admin.CheckBoxField do
  use Surface.Component
  alias Surface.Components.Form
  alias PanWeb.Surface.Admin.ErrorTag

  prop(name, :string, required: true)
  prop(label, :string, required: true)
  prop(redact, :boolean, required: false, default: false)

  def render(assigns) do
    ~F"""
    <Form.Field {=@name}
                class="my-2 flex items-center">
      {#if @redact}
        <div>**</div>
      {#else}
        <Form.Checkbox />
      {/if}
      <Form.Label class="italic pl-2">
        {@label}
      </Form.Label>
      {#if @redact}
        <div class="pl-2"> (redacted)</div>
      {/if}
      <ErrorTag />
    </Form.Field>
    """
  end
end
