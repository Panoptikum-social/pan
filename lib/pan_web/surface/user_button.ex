defmodule PanWeb.Surface.UserButton do
  use Surface.Component
  alias PanWeb.Surface.LinkButton
  alias PanWeb.Router.Helpers, as: Routes

  prop id, :integer, required: false
  prop name, :string, required: false
  prop for, :map, required: false

  def render(assigns) do
    ~H"""
    <LinkButton to={{ Routes.user_frontend_path(@socket, :show, @id || @for.id) }}
                class="bg-bittersweet text-white hover:bg-bittersweet-light"
                icon="female-solid"
                title={{ @name || @for.name }} />
    """
  end
end
