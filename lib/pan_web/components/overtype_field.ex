defmodule PanWeb.Component.OvertypeField do
  use PanWeb, :html

  # A markdown textarea the OvertypeField hook turns into an OverType editor;
  # without JavaScript the plain textarea stays.
  attr :field, Phoenix.HTML.FormField, required: true
  attr :label, :string, required: true

  def render(assigns) do
    ~H"""
    <div class="fieldset mb-2 w-full">
      <span class="label mb-1">{@label}</span>
      <div id={"#{@field.id}-overtype"} phx-hook="OvertypeField" phx-update="ignore">
        <textarea id={@field.id} name={@field.name} rows="10" class="w-full textarea">{Phoenix.HTML.Form.normalize_value("textarea", @field.value)}</textarea>
      </div>
    </div>
    """
  end
end
