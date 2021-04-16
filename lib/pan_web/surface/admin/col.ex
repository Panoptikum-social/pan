defmodule PanWeb.Surface.Admin.Col do
  use Surface.Component, slot: "cols"

  prop(title, :string, required: true)
  prop(class, :css_class, required: false)
  prop(width, :string, required: false)
end
