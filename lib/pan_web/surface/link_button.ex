defmodule PanWeb.Surface.LinkButton do
  use Surface.Component
  alias PanWeb.Surface.Icon

  prop title, :string, required: true
  prop href, :fun, required: true
  prop class, :css_class, required: false
  prop large, :boolean, required: false, default: false
  prop icon, :string, required: false
  prop truncate, :boolean, default: false

  def render(assigns) do
    ~H"""
    <span :if={{ @truncate }} class=""
          class={{ "text-sm fill-current border border-solid truncate inline-block",
                   @class,
                   "p-0.5 rounded": !@large,
                   "p-2.0 rounded-lg": @large }}>
      <a href={{ @href }}>
        <Icon :if={{ @icon }} name={{ @icon }} spaced={{ true }}/>
        {{ @title }}
      </a>
    </span>

    <a :if={{ !@truncate}}
        href={{ @href }}
        class={{ "text-sm fill-current border border-solid my-2",
                 @class,
                 "p-1 rounded": !@large,
                 "p-2.5 rounded-lg": @large }}>
        <Icon :if={{ @icon }} name={{ @icon }} spaced={{ true }}/>
        {{ @title }}
    </a>
    """
  end
end
