defmodule PanWeb.Component.PersonaButton do
  use PanWeb, :html
  alias PanWeb.Component.LinkButton
  alias PanWeb.Router.Helpers, as: Routes
  alias PanWeb.Endpoint

  attr :id, :integer, default: nil
  attr :name, :string, default: nil
  attr :for, :map, default: nil
  attr :class, :string, default: nil

  def render(assigns) do
    ~H"""
    <LinkButton.render to={Routes.persona_frontend_path(Endpoint, :show, @id || @for.id)}
                       class={["bg-lavender text-white border border-gray-dark hover:bg-lavender-light hover:border-lavender", @class]}
                       icon="user-astronaut-lineawesome-solid"
                       title={@name || @for.name} />
    """
  end
end
