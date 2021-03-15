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
                   "p-0.5 rounded text-sm": !@large,
                   "p-1.5 rounded-lg font-medium": @large }}>
      <a href={{ @href }}>
        <Icon :if={{ @icon }} name={{ @icon }} spaced={{ true }}/>
        {{ @title }}
      </a>&nbsp;
    </span>

    <a :if={{ !@truncate}}
        href={{ @href }}
        class={{ "border border-solid my-2",
                 @class,
                 "p-1 rounded text-sm": !@large,
                 "p-2 rounded-lg font-medium": @large }}>
        <Icon :if={{ @icon }} name={{ @icon }} spaced={{ true }}/>
        {{ @title }}
    </a>&nbsp;
    """
  end
end
