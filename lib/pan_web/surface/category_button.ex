defmodule PanWeb.Surface.CategoryButton do
  use Surface.Component
  alias PanWeb.Surface.LinkButton
  alias PanWeb.Router.Helpers, as: Routes
  import PanWeb.ViewHelpers
  alias PanWeb.Endpoint

  prop(id, :integer, required: false)
  prop(title, :string, required: false)
  prop(class, :string, required: false)
  prop(large, :boolean, required: false, default: false)
  prop(for, :map, required: false)
  prop(index_on_page, :integer, default: 1)
  prop(truncate, :boolean, default: false)

  def render(assigns) do
    ~F"""
    <LinkButton to={Routes.category_frontend_path(Endpoint, :show, @id || @for.id)}
                class={color_class_cycle(@index_on_page), @class}
                {=@large}
                icon="folder-heroicons-outline"
                title={@title || @for.title}
                {=@truncate} />
    """
  end
end
