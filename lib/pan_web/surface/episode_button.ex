defmodule PanWeb.Surface.EpisodeButton do
  use Surface.Component
  alias PanWeb.Surface.LinkButton
  alias PanWeb.Router.Helpers, as: Routes
  alias PanWeb.Endpoint

  prop(id, :integer, required: false)
  prop(title, :string, required: false)
  prop(class, :string, required: false)
  prop(large, :boolean, default: false)
  prop(for, :map, required: false)
  prop(truncate, :boolean, default: false)

  def render(assigns) do
    ~F"""
    <LinkButton to={Routes.episode_frontend_path(Endpoint, :show, @id || @for.id)}
                class={"bg-aqua text-white border-gray-dark
                       hover:bg-aqua-light hover:border-aqua", @class}
                icon="headphones-lineawesome-solid"
                title={@title || @for.title}
                {=@large}
                truncate={@truncate} />
    """
  end
end
