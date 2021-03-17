defmodule PanWeb.Surface.PersonaButton do
  use Surface.Component
  alias PanWeb.Surface.LinkButton
  alias PanWeb.Router.Helpers, as: Routes

  prop id, :integer, required: false
  prop name, :string, required: false
  prop for, :map, required: false

  def render(assigns) do
    ~H"""
    <LinkButton
      href={{ Routes.persona_frontend_path(@socket, :show, @id || @for.id) }}
      class="bg-lavender text-white hover:bg-lavender-light"
      icon="user-astronaut-solid"
      title={{ @name || @for.title }} />
    """
  end
end
