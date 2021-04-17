defmodule PanWeb.Surface.Admin.ToolbarItem do
  use Surface.Component, slot: "toolbar_items"

  prop(title, :string, required: true)
  prop(message, :atom, required: true)
  prop(when_selected_count, :atom, values: [:any, :zero, :one, :two, :nonzero],
                                   default: :any)
end
