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
  prop(class, :css_class, required: false)

  slot(default)
  slot(panel_heading, required: false)

  def heading_color_classes(purpose) do
    case purpose do
      "category" -> "bg-category text-white"
      "podcast" -> "bg-podcast text-white"
      "popular" -> "bg-aqua text-white"
      "like" -> "bg-grapefruit text-white"
      "episode" -> "bg-episode text-white"
      "recommendation" -> "bg-recommendation text-white"
      _ -> "bg-white"
    end
  end

  def render(assigns) do
    ~F"""
    <div aria-label="panel" class={"rounded-xl shadow", @class}>
      <div aria-label="panel heading"
           class={"p-3 rounded-t-xl", heading_color_classes(@purpose)}>
        <#slot name="panel_heading" />

        {#if !@target}
          {@heading}
        {/if}
        <Link :if={@target}
              to={@target}
              class="hover:text-gray-lighter"
              label={@heading} />
        <Link :if={@target}
              to={@target}
              class="float-right hover:text-gray-lighter"
              label={@heading_right} />
      </div>

      <div class="border-l border-r border-b border-gray-lighter rounded-b-xl">
        <#slot>No content defined!</#slot>
      </div>
    </div>
    """
  end
end
