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
    <div :if={{ @truncate }} class="truncate inline-block py-0.5">
      <a href={{ @href }}
        class={{ "text-sm fill-current border border-solid rounded",
                 @class,
                 "px-1.5 py-0.5": !@large,
                 "px-2.5 py-1.5": @large }}>
          <Icon :if={{ @icon }} name={{ @icon }} spaced={{ true }}/>
          {{ @title }}
      </a>
    </div>

    <a :if={{ !@truncate}}
        href={{ @href }}
        class={{ "text-sm fill-current border border-solid my-2 rounded leading-8",
                 @class,
                 "px-1.5 py-0.5": !@large,
                 "px-2.5 py-1.5": @large }}>
        <Icon :if={{ @icon }} name={{ @icon }} spaced={{ true }}/>
        {{ @title }}
    </a>
    """
  end
end
