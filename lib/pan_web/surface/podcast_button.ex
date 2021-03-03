defmodule PanWeb.Surface.PodcastButton do
  use Surface.Component
  alias PanWeb.Surface.LinkButton
  alias PanWeb.Router.Helpers, as: Routes

  prop id, :integer, required: false
  prop title, :string, required: false
  prop for, :map, required: false

  def render(assigns) do
    ~H"""
    <LinkButton
      href={{ Routes.podcast_frontend_path(@socket, :show, @id || @for.id) }}
      class="bg-white text-black border-coolGray-400 hover:bg-gray-500 hover:text-white"
      icon="podcast-solid"
      title={{ @title || @for.title }} />
    """
  end
end
