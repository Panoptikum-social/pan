defmodule PanWeb.Surface.EpisodeButton do
  use Surface.Component
  alias PanWeb.Surface.LinkButton
  alias PanWeb.Router.Helpers, as: Routes

  prop id, :integer, required: false
  prop title, :string, required: false
  prop for, :map, required: false

  def render(assigns) do
    ~H"""
    <LinkButton to={{ Routes.episode_frontend_path(@socket, :show, @id || @for.id) }}
                class="bg-aqua text-white hover:bg-aqua-light"
                icon="headphones-solid"
                title={{ @title || @for.title }} />
    """
  end
end
