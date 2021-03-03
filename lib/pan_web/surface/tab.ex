defmodule PanWeb.Surface.Tab do
  use Surface.Component

  prop items, :list, required: true

  slot default, props: [item: ^items]
end
