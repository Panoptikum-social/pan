defmodule PanWeb.Component.EntityLink do
  use PanWeb, :html

  # A podcast, episode, category, persona or user as a link: the entity's
  # icon in its color, the title in the text color (backlog.md #438).
  attr :id, :string, default: nil
  attr :to, :string, required: true
  attr :icon, :string, required: true
  attr :icon_class, :string, default: nil, doc: "the color, e.g. text-podcast"
  attr :title, :string, required: true
  attr :large, :boolean, default: false
  attr :truncate, :boolean, default: false
  attr :class, :any, default: nil
  slot :inner_block, doc: "shown after the title"

  def render(assigns) do
    ~H"""
    <.link
      id={@id}
      href={@to}
      class={[
        "inline-flex items-center gap-1.5 align-bottom hover:underline",
        @large && "text-xl font-semibold",
        @truncate && "max-w-full",
        @class
      ]}
    >
      <.icon
        name={@icon}
        class={"shrink-0 #{if @large, do: "size-7", else: "size-5"} #{@icon_class}"}
      />
      <span class={@truncate && "truncate"}>{@title}</span>
      {render_slot(@inner_block)}
    </.link>
    """
  end
end
