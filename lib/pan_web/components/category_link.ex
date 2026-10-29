defmodule PanWeb.Component.CategoryLink do
  use PanWeb, :html
  alias PanWeb.Router.Helpers, as: Routes
  alias PanWeb.Endpoint

  # A category as a link with its icon in the category color (backlog.md
  # #439). Only top level categories have a color, subcategories pass their
  # parent's; without an icon the folder icon stands in.
  attr :for, :map, required: true
  attr :color, :string, default: nil
  attr :large, :boolean, default: false
  attr :count, :integer, default: nil, doc: "number shown after the title, e.g. podcasts"
  attr :class, :string, default: nil

  def render(assigns) do
    ~H"""
    <.link
      navigate={Routes.category_frontend_path(Endpoint, :show, @for.id)}
      class={[
        "inline-flex items-center gap-1.5 hover:underline",
        @large && "text-xl font-semibold",
        @class
      ]}
    >
      <.icon
        name={@for.icon || "folder"}
        class={"shrink-0 #{if @large, do: "size-7", else: "size-5"} #{@color && "text-ctp-#{@color}"}"}
      />
      {@for.title}
      <span :if={@count} class="text-xs font-normal opacity-70 tabular-nums">{@count}</span>
    </.link>
    """
  end
end
