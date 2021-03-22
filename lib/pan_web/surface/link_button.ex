defmodule PanWeb.Surface.LinkButton do
  use Surface.Component
  alias PanWeb.Surface.Icon
  alias Surface.Components.Link

  prop title, :string, required: true
  prop to, :fun, required: true
  prop class, :css_class, required: false
  prop large, :boolean, required: false, default: false
  prop icon, :string, required: false
  prop truncate, :boolean, default: false

  def render(assigns) do
    ~H"""
    <Link to={{ @to }}
          class={{ "border border-solid inline-block shadow",
                   @class,
                   "truncate max-w-full": @truncate,
                   "py-1 px-2 rounded text-sm": !@large,
                   "py-2 px-3 rounded-md": @large }}>
        <Icon :if={{ @icon }}
              name={{ @icon }}
              spaced={{ true }}/>
        {{ @title }}
    </Link>
    """
  end
end
