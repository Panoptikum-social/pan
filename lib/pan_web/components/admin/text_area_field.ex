defmodule PanWeb.Components.Admin.TextAreaField do
  use PanWeb, :html
  use Phoenix.Component

  attr :name, :string, required: true
  attr :value, :any, default: nil
  attr :label, :string, default: nil
  attr :redact, :boolean, default: false

  def render(assigns) do
    ~H"""
    <div class="flex-1 flex flex-col mb-2 min-h-0">
      <label class="flex flex-col flex-1">
        <span class="label mb-1">{@label || Phoenix.Naming.humanize(@name)}</span>
        <textarea name={@name}
                  class="w-full textarea textarea-sm flex-1 min-h-20"
                  disabled={@redact}
        >{if @redact, do: "** redacted **", else: (@value || "")}</textarea>
      </label>
    </div>
    """
  end
end
