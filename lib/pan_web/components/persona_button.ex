defmodule PanWeb.Component.PersonaButton do
  use PanWeb, :html
  import PanWeb.ViewHelpers, only: [truncate_string: 2]
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
      to={Routes.persona_frontend_path(Endpoint, :show, @id || @for.id)}
      class={@class}
      icon="user-star"
      icon_class="text-persona"
      title={truncate_string(@name || @for.name, 80)}
    />
    """
  end
end
