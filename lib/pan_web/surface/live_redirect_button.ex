defmodule PanWeb.Surface.LiveRedirectButton do
  use PanWeb, :html
  alias PanWeb.Surface.Icon

  attr :id, :string, default: nil
  attr :title, :string, required: true
  attr :to, :string, required: true
  attr :class, :string, default: nil
  attr :large, :boolean, default: false
  attr :icon, :string, default: nil
  attr :truncate, :boolean, default: false
  attr :method, :atom, default: :get
  attr :opts, :list, default: []

  def render(assigns) do
    ~H"""
    <.link navigate={@to}
           class={[
             "border border-solid inline-block shadow",
             @class,
             @truncate && "truncate max-w-full",
             !@large && "py-1 px-2 rounded text-sm",
             @large && "py-2 px-3 rounded-md"
           ]}
           {@opts}>
      <Icon.render :if={@icon} name={@icon} spaced={true} />
      {@title}
    </.link>
    """
  end
end
