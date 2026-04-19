defmodule PanWeb.Surface.UserButton do
  use PanWeb, :html
  alias PanWeb.Surface.LinkButton
  alias PanWeb.Router.Helpers, as: Routes
  alias PanWeb.Endpoint

  attr :id, :integer, default: nil
  attr :name, :string, default: nil
  attr :for, :map, default: nil

  def render(assigns) do
    ~H"""
    <LinkButton.render to={Routes.user_frontend_path(Endpoint, :show, @id || @for.id)}
                       class="bg-bittersweet text-white border-gray-dark hover:bg-bittersweet-light hover:border-bittersweet"
                       icon="female-lineawesome-solid"
                       title={@name || @for.name} />
    """
  end
end
