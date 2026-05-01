defmodule PanWeb.Component.EventButton do
  use PanWeb, :html
  alias PanWeb.Component.Icon

  attr :title, :string, default: nil
  attr :event, :string, required: true
  attr :target, :any, default: nil
  attr :class, :string, default: nil
  attr :large, :boolean, default: false
  attr :icon, :string, default: nil
  attr :truncate, :boolean, default: false
  attr :alt, :string, default: nil

  slot :inner_block

  def render(assigns) do
    ~H"""
    <a phx-click={@event} phx-target={@target}
       alt={@alt}
       class={[
         "border border-solid inline-block shadow",
         @class,
         !@class && "bg-gray-lighter hover:bg-gray-lightest",
         @truncate && "truncate max-w-full",
         !@large && "py-1 px-2 rounded text-sm",
         @large && "py-2 px-3 rounded-md"
       ]}>
      <Icon.render :if={@icon} name={@icon} spaced={true} />
      {@title}
      {render_slot(@inner_block)}
    </a>
    """
  end
end
