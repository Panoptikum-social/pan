defmodule PanWeb.Surface.Admin.PaginationLink do
  use Surface.Component

  prop page, :integer
  prop per_page, :integer
  prop disabled, :css_class

  slot default, required: true

  def render(assigns) do
    ~H"""
    <a href="#"
       class={{"border p-2 text-blue-500", @disabled}}
       click="paginate"
       phx_value_page={{ @page }}
       phx_value_per_page={{ @per_page }}>
      <slot/>
    </a>
    """
  end
end
