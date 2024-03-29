defmodule PanWeb.Surface.Admin.PerPageLink do
  use Surface.Component

  prop(delta, :integer, required: true)
  prop(click, :event, required: true)

  def render(assigns) do
    ~F"""
    <button :on-click={@click}
            phx-value-delta={@delta}
            class="border border-gray bg-white hover:bg-gray-lighter px-1 py-0.5 lg:px-2 lg:py-0 my-1 rounded">
      {@delta}
    </button>
    """
  end
end
