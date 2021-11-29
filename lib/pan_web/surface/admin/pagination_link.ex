defmodule PanWeb.Surface.Admin.PaginationLink do
  use Surface.Component

  prop(page, :integer, required: true)
  prop(disabled, :boolean, required: false, default: false)
  prop(class, :css_class, required: false)
  prop(target, :string, required: true)

  slot(default, required: true)

  def render(assigns) do
    ~F"""
    <button href="#"
            class={"border border-gray bg-white hover:bg-gray-lighter px-1 py-0.5 lg:px-2 lg:py-0 my-1 rounded",
                   @class}
            :on-click={"paginate", target: @target}
            phx-value-page={@page}>
      <#slot/>
    </button>
    """
  end
end
