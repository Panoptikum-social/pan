defmodule PanWeb.Component.Panel do
  use PanWeb, :html

  def heading_color_classes(purpose) do
    case purpose do
      "info"           -> "bg-info text-white"
      "category"       -> "bg-category text-white"
      "podcast"        -> "bg-podcast text-white"
      "persona"        -> "bg-warning text-white"
      "popular"        -> "bg-aqua text-white"
      "like"           -> "bg-grapefruit text-white"
      "user"           -> "bg-lavender text-white"
      "episode"        -> "bg-episode text-white"
      "engagement"     -> "bg-bittersweet text-white"
      "gig"            -> "bg-mint text-white"
      "recommendation" -> "bg-recommendation text-white"
      "message"        -> "bg-success text-white"
      _                -> "bg-white"
    end
  end

  attr :heading, :string, default: nil
  attr :purpose, :string, default: "default"
  attr :heading_right, :string, default: nil
  attr :target, :string, default: nil
  attr :class, :string, default: ""
  attr :id, :string, default: nil
  attr :content_class, :string, default: ""

  slot :inner_block
  slot :panel_heading

  def render(assigns) do
    ~H"""
    <div aria-label="panel"
         class={["rounded-xl shadow", @class]}
         id={@id}>
      <div aria-label="panel heading"
           class={["p-3 rounded-t-xl", heading_color_classes(@purpose)]}>
        {render_slot(@panel_heading)}

        <%= if @target do %>
          <.link href={@target}
                 class="hover:text-gray-lighter">{@heading}</.link>
          <.link :if={@heading_right}
                 href={@target}
                 class="float-right hover:text-gray-lighter">{@heading_right}</.link>
        <% else %>
          {@heading}
        <% end %>
      </div>

      <div class={@content_class}>
        <%= if @inner_block != [] do %>
          {render_slot(@inner_block)}
        <% else %>
          No content defined!
        <% end %>
      </div>
    </div>
    """
  end
end
