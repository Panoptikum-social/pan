defmodule PanWeb.Surface.Admin.PaginationLink do
  use Surface.Component

  prop page, :integer, required: true
  prop per_page, :integer, required: true
  prop disabled, :css_class, required: false, default: false
  prop class, :css_class, required: false
  prop target, :string, required: true

  slot default, required: true

  def render(assigns) do
    ~H"""
    <a href="#"
       class={{ "p-2 text-white bg-info hover:bg-info-light",
                @class,
                disabled: @disabled }}
       :on-click={{ "paginate", target: @target}}
       phx-value-page={{ @page }}
       phx-value-per-page={{ @per_page }}>
      <slot/>
    </a>
    """
  end
end
