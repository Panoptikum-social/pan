defmodule PanWeb.Surface.EventButton do
  use Surface.Component
  alias PanWeb.Surface.Icon

  prop(title, :string, required: false)
  prop(event, :event, required: true)
  prop(class, :css_class, required: false)
  prop(large, :boolean, required: false, default: false)
  prop(icon, :string, required: false)
  prop(truncate, :boolean, default: false)
  prop(alt, :string, required: false)
  slot(default)

  def render(assigns) do
    ~F"""
    <a :on-click={@event}
       alt={@alt}
       class={"border border-solid inline-block shadow",
              @class,
              "bg-gray-lighter hover:bg-gray-lightest": !@class,
              "truncate max-w-full": @truncate,
              "py-1 px-2 rounded text-sm": !@large,
              "py-2 px-3 rounded-md": @large}>
        <Icon :if={@icon} name={@icon} spaced/>
        {@title}
        <#slot />
    </a>
    """
  end
end
