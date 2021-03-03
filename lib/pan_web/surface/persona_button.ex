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
      class="bg-violet-400 border-violet-500 text-white hover:bg-violet-300 hover:text-gray-800"
      icon="user-astronaut-solid"
      title={{ @name || @for.title }} />
    """
  end
end
