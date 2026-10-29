defmodule PanWeb.Component.UserButton do
  use PanWeb, :html
  alias PanWeb.Component.EntityLink
  alias PanWeb.Router.Helpers, as: Routes
  alias PanWeb.Endpoint

  attr :id, :integer, default: nil
  attr :name, :string, default: nil
  attr :for, :map, default: nil
  attr :class, :string, default: nil

  def render(assigns) do
    ~H"""
    <EntityLink.render
      to={Routes.user_frontend_path(Endpoint, :show, @id || @for.id)}
      class={@class}
      icon="woman"
      icon_class="text-user"
      title={@name || @for.name}
    />
    """
  end
end
