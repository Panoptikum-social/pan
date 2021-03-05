defmodule PanWeb.Surface.CategoryButton do
  use Surface.Component
  alias PanWeb.Surface.LinkButton
  alias PanWeb.Router.Helpers, as: Routes
  import PanWeb.ViewHelpers

  prop id, :integer, required: false
  prop title, :string, required: false
  prop class, :string, required: false
  prop large, :boolean, required: true
  prop for, :map, required: false
  prop index_on_page, :integer, default: 0
  prop truncate, :boolean, default: false

  def render(assigns) do
    ~H"""
    <LinkButton
      href={{ Routes.category_frontend_path(@socket, :show, @id || @for.id) }}
      class={{ color_class_cycle(@index_on_page), {@class, @class}  }}
      large={{ @large }}
      icon="folder"
      title={{ @title || @for.title }}
      truncate={{ @truncate }} />
    """
  end
end
