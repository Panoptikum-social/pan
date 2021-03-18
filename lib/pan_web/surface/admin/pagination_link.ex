defmodule PanWeb.Surface.Admin.PaginationLink do
  use Surface.Component

  prop page, :integer, required: true
  prop per_page, :integer, required: true
  prop disabled, :css_class, required: false, default: false
  prop class, :css_class, required: false

  slot default, required: true

  def render(assigns) do
    ~H"""
    <a href="#"
       class={{ "p-2 text-white bg-info hover:bg-info-light",
                @class,
                disabled: @disabled }}
       click="paginate"
       phx_value_page={{ @page }}
       phx_value_per_page={{ @per_page }}>
      <slot/>
    </a>
    """
  end
end
