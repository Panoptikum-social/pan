defmodule PanWeb.Surface.PodcastButton do
  use Surface.Component
  alias PanWeb.Surface.LinkButton
  alias PanWeb.Router.Helpers, as: Routes

  prop id, :integer, required: false
  prop title, :string, required: true
  prop podcast, :map, required: false

  def render(assigns) do
    ~H"""
    <LinkButton
      href={{ Routes.podcast_frontend_path(@socket, :show, @id) }}
      class="bg-white text-black border-coolGray-400 hover:bg-gray-200 hover:text-gray-800"
      icon="podcast-solid"
      title={{ @title }} />
    """
  end
end
