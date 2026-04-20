defmodule PanWeb.Admin.PaginationLink do
  use PanWeb, :html

  attr :page, :integer, required: true
  attr :disabled, :boolean, default: false
  attr :class, :string, default: nil
  attr :click, :string, required: true
  attr :target, :any, default: nil

  slot :inner_block, required: true

  def render(assigns) do
    ~H"""
    <button href="#"
            class={["border border-gray bg-white hover:bg-gray-lighter px-1 py-0.5 lg:px-2 lg:py-0 my-1 rounded", @class]}
            phx-click={@click}
            phx-target={@target}
            phx-value-page={@page}>
      {render_slot(@inner_block)}
    </button>
    """
  end
end
