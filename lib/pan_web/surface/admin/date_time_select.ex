defmodule PanWeb.Surface.Admin.DateTimeSelect do
  use Surface.Component
  alias Surface.Components.Form
  import Phoenix.HTML.Form

  prop(name, :string, required: true)

  def render_builder(assigns, b) do
    ~H"""
    <div class="ml-3 px-4 py-0 rounded-none">
      📅 {{ b.(:day, [class: "w-16"]) }} {{ b.(:month, []) }} {{ b.(:year, [class: "w-20"]) }}
      🕒 {{ b.(:hour, [class: "w-16"]) }} : {{ b.(:minute, [class: "w-16"]) }}
    </div>
    """
  end

  def render(assigns) do
    ~H"""
    <Form.Field name={{ @name |> String.to_atom() }} class="my-2 flex items-center justify-end">
      <Form.Label class="italic"/>
      <Context get={{ form: form, field: field }}>
        {{ datetime_select(form, field, builder: fn b -> render_builder(assigns, b) end) }}
      </Context>
      <Form.ErrorTag />
    </Form.Field>
    """
  end
end
