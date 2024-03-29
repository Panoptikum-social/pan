defmodule PanWeb.Surface.UserButton do
  use Surface.Component
  alias PanWeb.Surface.LinkButton
  alias PanWeb.Router.Helpers, as: Routes
  alias PanWeb.Endpoint

  prop(id, :integer, required: false)
  prop(name, :string, required: false)
  prop(for, :map, required: false)

  def render(assigns) do
    ~F"""
    <LinkButton to={Routes.user_frontend_path(Endpoint, :show, @id || @for.id)}
                class="bg-bittersweet text-white border-gray-dark
                       hover:bg-bittersweet-light hover:border-bittersweet"
                icon="female-lineawesome-solid"
                title={@name || @for.name} />
    """
  end
end
