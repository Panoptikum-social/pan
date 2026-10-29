defmodule PanWeb.Component.Panel do
  use PanWeb, :html

  # Neutral headings, the panel framed in the color of what it lists; the
  # icons in the content carry the color (backlog.md #433).
  @heading_colors %{
    "info" => "border-ctp-sky",
    "category" => "border-category",
    "podcast" => "border-podcast",
    "persona" => "border-persona",
    "popular" => "border-ctp-sky",
    "like" => "border-ctp-red",
    "user" => "border-user",
    "episode" => "border-episode",
    "engagement" => "border-ctp-peach",
    "gig" => "border-ctp-green",
    "recommendation" => "border-recommendation",
    "message" => "border-ctp-pink"
  }

  def border_color_class(purpose), do: Map.get(@heading_colors, purpose, "border-base-300")

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
    <div
      aria-label="panel"
      class={["rounded-xl shadow border-2", border_color_class(@purpose), @class]}
      id={@id}
    >
      <div
        aria-label="panel heading"
        class={["p-3 rounded-t-[0.6rem] bg-base-300 border-b-2", border_color_class(@purpose)]}
      >
        {render_slot(@panel_heading)}

        <%= if @target do %>
          <.link
            href={@target}
            class="hover:underline"
          >{@heading}</.link>
          <.link
            :if={@heading_right}
            href={@target}
            class="float-right hover:underline"
          >{@heading_right}</.link>
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
