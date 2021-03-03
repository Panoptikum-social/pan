defmodule PanWeb.Surface.EpisodeButton do
  use Surface.Component
  alias PanWeb.Surface.LinkButton
  alias PanWeb.Router.Helpers, as: Routes

  prop id, :integer, required: false
  prop title, :string, required: false
  prop for, :map, required: false

  def render(assigns) do
    ~H"""
    <LinkButton
      href={{ Routes.episode_frontend_path(@socket, :show, @id || @for.id) }}
      class="bg-lightBlue-400 text-white border-lightBlue-500 hover:bg-lightBlue-300 hover:text-gray-800"
      icon="headphones-solid"
      title={{ @title || @for.title }} />
    """
  end
end
