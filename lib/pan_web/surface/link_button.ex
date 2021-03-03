defmodule PanWeb.Surface.LinkButton do
  use Surface.Component
  alias PanWeb.Surface.Icon

  prop title, :string, required: true
  prop href, :fun, required: true
  prop class, :string, required: false
  prop icon, :string, required: false

  def render(assigns) do
    ~H"""
    <a href={{ @href }}
       class={{ "text-sm fill-current border border-solid px-2 py-1 leading-normal truncate", @class }}>
      <Icon :if={{ @icon }} name={{ @icon }} spaced={{ true }}/>
      {{ @title }}
    </a>
    """
  end
end
