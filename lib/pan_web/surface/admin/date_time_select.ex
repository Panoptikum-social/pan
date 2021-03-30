defmodule PanWeb.Surface.Admin.DateTimeSelect do
  use Surface.Component
  alias Surface.Components.Form
  alias Surface.Components.Form.Input.InputContext
  alias PanWeb.Surface.Admin.ErrorTag
  import Phoenix.HTML.Form

  prop(name, :string, required: true)

  def render(assigns) do
    ~H"""
    <Form.Field name={{ @name |> String.to_atom() }} class="my-2 flex items-center justify-end">
      <Form.Label class="italic"/>
      <InputContext assigns={{ assigns }} :let={{ form: form, field: field }}>
        {{ datetime_select(form, field, builder: fn b -> render_builder(assigns, b) end) }}
      </InputContext>
      <ErrorTag />
    </Form.Field>
    """
  end

  def render_builder(assigns, b) do
    ~H"""
    <div class="ml-3 px-4 py-0 rounded-none">
      📅 {{ b.(:day, [class: "w-16 px-2 py-0 rounded-none"]) }}
          {{ b.(:month, [class: "w-32 px-2 py-0 rounded-none"]) }}
          {{ b.(:year, [class: "w-20 px-2 py-0 rounded-none"]) }}
      🕒 {{ b.(:hour, [class: "w-16 px-2 py-0 rounded-none"]) }} :
          {{ b.(:minute, [class: "w-16 px-2 py-0 rounded-none"]) }}
    </div>
    """
  end
end
