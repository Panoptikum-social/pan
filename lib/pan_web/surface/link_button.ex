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
          class={{ "border border-solid truncate inline-block",
                   @class,
                   "py-0.5 px-1.5 rounded text-sm": !@large,
                   "py-1.5 px-2.5 rounded-md": @large }}>
      <a href={{ @href }}>
        <Icon :if={{ @icon }} name={{ @icon }} spaced={{ true }}/>
        {{ @title }}
      </a>
    </span>

    <a :if={{ !@truncate}}
        href={{ @href }}
        class={{ "border border-solid my-2",
                 @class,
                 "py-1 px-2 rounded text-sm": !@large,
                 "py-2 px-3 rounded-md": @large }}>
        <Icon :if={{ @icon }} name={{ @icon }} spaced={{ true }}/>
        {{ @title }}
    </a>
    """
  end
end
