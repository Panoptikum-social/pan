defmodule PanWeb.Surface.Admin.DateTimeSelect do
  use Surface.Component
  alias Surface.Components.Form
  alias Surface.Components.Form.Input.InputContext
  alias PanWeb.Surface.Admin.ErrorTag
  import Phoenix.HTML.Form

  prop(name, :string, required: true)
  prop(redact, :boolean, required: false, default: false)

  def render(assigns) do
    ~F"""
    <Form.Field name={@name} class={"my-2 flex items-center", "justify-end": !@redact}>
      <Form.Label class="italic"/>
      <div class="ml-3 flex flex-col items-start">
        <InputContext :if={!@redact}
                      assigns={assigns}
                      :let={form: form, field: field}>
          {datetime_select(form, field, builder: fn b -> render_builder(assigns, b) end)}
        </InputContext>
        <Form.TextInput :if={@redact}
                        value="** redacted **"
                        class="w-32 px-2 py-0 rounded-none"
                        opts={disabled: true} />
        <ErrorTag/>
      </div>
    </Form.Field>
    """
  end

  def render_builder(assigns, b) do
    ~F"""
    <div class="py-0 rounded-none">
      📅 {b.(:day, [class: "w-16 px-2 py-0 rounded-none"])}
          {b.(:month, [class: "w-32 px-2 py-0 rounded-none"])}
          {b.(:year, [class: "w-20 px-2 py-0 rounded-none"])}
      🕒 {b.(:hour, [class: "w-16 px-2 py-0 rounded-none"])} :
          {b.(:minute, [class: "w-16 px-2 py-0 rounded-none"])}
    </div>
    """
  end
end
