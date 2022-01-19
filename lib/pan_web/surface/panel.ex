defmodule PanWeb.Surface.PanelHeading do
  use Surface.Component, slot: "panel_heading"
end

defmodule PanWeb.Surface.Panel do
  use Surface.Component
  alias PanWeb.Surface.Link
  alias Surface.Components.Link

  prop(heading, :string, required: false)
  prop(purpose, :string, required: false, default: "default")
  prop(heading_right, :string, required: false)
  prop(target, :fun, required: false)
  prop(class, :css_class, required: false, default: "")
  prop(id, :string, required: false)

  slot(default)
  slot(panel_heading, required: false)

  def heading_color_classes(purpose) do
    case purpose do
      "info" -> "bg-info text-white"
      "category" -> "bg-category text-white"
      "podcast" -> "bg-podcast text-white"
      "persona" -> "bg-warning text-white"
      "popular" -> "bg-aqua text-white"
      "like" -> "bg-grapefruit text-white"
      "user" -> "bg-lavender text-white"
      "episode" -> "bg-episode text-white"
      "engagement" -> "bg-bittersweet text-white"
      "gig" -> "bg-mint text-white"
      "recommendation" -> "bg-recommendation text-white"
      "message" -> "bg-success text-white"
      _ -> "bg-white"
    end
  end

  def render(assigns) do
    ~F"""
    <div aria-label="panel"
         class={"rounded-xl shadow", @class}
         id={@id}>
      <div aria-label="panel heading"
           class={"p-3 rounded-t-xl", heading_color_classes(@purpose)}>
        <#slot name="panel_heading" />

        {#if @target}
          <Link to={@target}
                class="hover:text-gray-lighter"
                label={@heading} />
          <Link :if={@heading_right}
                to={@target}
                class="float-right hover:text-gray-lighter"
                label={@heading_right} />
        {#else}
          {@heading}
        {/if}
      </div>

      <div class="border-l border-r border-b border-gray-lighter rounded-b-xl">
        <#slot>No content defined!</#slot>
      </div>
    </div>
    """
  end
end
