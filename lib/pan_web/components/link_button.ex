defmodule PanWeb.Component.LinkButton do
  use PanWeb, :html
  alias PanWeb.Component.Icon

  attr :id, :string, default: nil
  attr :title, :string, required: true
  attr :to, :string, required: true
  attr :class, :any, default: nil
  attr :large, :boolean, default: false
  attr :icon, :string, default: nil
  attr :truncate, :boolean, default: false
  attr :method, :atom, default: :get
  attr :opts, :list, default: []

  def render(assigns) do
    ~H"""
    <.link id={@id}
           href={@to}
           class={[
             "btn",
             @class,
             @truncate && "truncate max-w-full",
             !@large && "btn-sm"
           ]}
           method={@method}
           {@opts}>
      <Icon.render :if={@icon} name={@icon} spaced={true} />
      {@title}
    </.link>
    """
  end
end
