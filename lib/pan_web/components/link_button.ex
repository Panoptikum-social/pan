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

  slot :inner_block, doc: "shown after the title"

  def render(assigns) do
    ~H"""
    <.link
      id={@id}
      href={@to}
      class={[
        "btn",
        @class,
        @truncate && "truncate max-w-full",
        !@large && "btn-sm"
      ]}
      method={@method}
      {@opts}
    >
      <Icon.render :if={@icon} name={@icon} class="shrink-0" spaced={true} />
      {@title}
      {render_slot(@inner_block)}
    </.link>
    """
  end
end
