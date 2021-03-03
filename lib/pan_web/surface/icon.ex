defmodule PanWeb.Surface.Icon do
  use Surface.Component
  import PanWeb.ViewHelpers

  prop name, :string, required: true
  prop spaced, :boolean, required: false, default: false
end
