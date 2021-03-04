defmodule PanWeb.Surface.LinkButton do
  use Surface.Component
  alias PanWeb.Surface.Icon

  prop title, :string, required: true
  prop href, :fun, required: true
  prop class, :string, required: false
  prop icon, :string, required: false
  prop truncate, :boolean, default: false

  def render(assigns) do
    ~H"""
    <If condition={{ @truncate }}>
      <div class="truncate px-1 py-1 leading-normal">
        <a href={{ @href }}
          class={{ "text-sm fill-current border border-solid px-1 py-1 rounded", @class }}>
            <Icon :if={{ @icon }} name={{ @icon }} spaced={{ true }}/>
            {{ @title }}
        </a>
      </div>
    </If>

    <If condition={{ !@truncate }}>
      <a href={{ @href }}
        class={{ "text-sm fill-current border border-solid px-1 py-1 leading-normal rounded", @class }}>
          <Icon :if={{ @icon }} name={{ @icon }} spaced={{ true }}/>
          {{ @title }}
      </a>
    </If>
    """
  end
end
