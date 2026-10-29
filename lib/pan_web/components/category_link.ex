defmodule PanWeb.Component.CategoryLink do
  use PanWeb, :html
  alias PanWeb.Component.EntityLink
  alias PanWeb.Router.Helpers, as: Routes
  alias PanWeb.Endpoint

  # A category as a link with its icon in the category color (backlog.md
  # #439). Only top level categories have a color, subcategories use their
  # parent's (see PanWeb.Category.color_map/0); without an icon the folder
  # icon stands in.
  attr :for, :map, required: true
  attr :color, :string, default: nil
  attr :large, :boolean, default: false
  attr :truncate, :boolean, default: false
  attr :count, :integer, default: nil, doc: "number shown after the title, e.g. podcasts"
  attr :class, :any, default: nil

  def render(assigns) do
    ~H"""
    <EntityLink.render
      to={Routes.category_frontend_path(Endpoint, :show, @for.id)}
      icon={@for.icon || "folder"}
      icon_class={@color && "text-ctp-#{@color}"}
      title={@for.title}
      large={@large}
      truncate={@truncate}
      class={@class}
    >
      <span :if={@count} class="text-xs font-normal opacity-70 tabular-nums">{@count}</span>
    </EntityLink.render>
    """
  end
end
