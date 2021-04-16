defmodule PanWeb.Surface.Admin.Explorer do
  use Surface.LiveComponent

  prop(heading, :string, required: false, default: "Records")
  prop(cols, :list, required: false, default: [])
  prop(class, :css_class, required: false)

  data(records, :list, default: [])
  data(columns, :list, default: [])
  slot(slot_columns)

  def update(assigns, socket) do
    columns = if assigns.cols == [], do: assigns.slot_columns, else: assigns.cols

    socket =
      assign(socket, assigns)
      |> assign(columns: columns)
    {:ok, socket}
  end
end
