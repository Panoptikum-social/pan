defmodule PanWeb.Surface.PersonaButton do
  use Surface.Component
  alias PanWeb.Surface.LinkButton
  alias PanWeb.Router.Helpers, as: Routes
  alias PanWeb.Endpoint

  prop(id, :integer, required: false)
  prop(name, :string, required: false)
  prop(for, :map, required: false)

  def render(assigns) do
    ~F"""
    <LinkButton to={Routes.persona_frontend_path(Endpoint, :show, @id || @for.id)}
                class="bg-lavender text-white border border-gray-dark
                       hover:bg-lavender-light hover:border-lavender"
                icon="user-astronaut-lineawesome-solid"
                title={@name || @for.title} />
    """
  end
end
