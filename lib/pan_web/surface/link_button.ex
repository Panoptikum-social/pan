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
    <div :if={{ @truncate }} class="truncate py-1 inline-block">
      <a href={{ @href }}
        class={{ "fill-current border border-solid px-1 py-1 my-2 rounded",
                 @class,
                 "text-sm": !@large,
                 "text-l": @large }}>
          <Icon :if={{ @icon }} name={{ @icon }} spaced={{ true }}/>
          {{ @title }}
      </a>
    </div>

    <a :if={{ !@truncate}}
        href={{ @href }}
        class={{ "fill-current border border-solid px-1 py-1 my-2 rounded leading-8",
                 @class,
                 "text-sm": !@large,
                 "text-l": @large }}>
        <Icon :if={{ @icon }} name={{ @icon }} spaced={{ true }}/>
        {{ @title }}
    </a>
    """
  end
end
