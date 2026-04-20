defmodule PanWeb.Component.EpisodeButton do
  use PanWeb, :html
  alias PanWeb.Component.LinkButton
  alias PanWeb.Router.Helpers, as: Routes
  alias PanWeb.Endpoint

  attr :id, :integer, default: nil
  attr :title, :string, default: nil
  attr :class, :string, default: nil
  attr :large, :boolean, default: false
  attr :for, :map, default: nil
  attr :truncate, :boolean, default: false

  def render(assigns) do
    ~H"""
    <LinkButton.render to={Routes.episode_frontend_path(Endpoint, :show, @id || @for.id)}
                       class={["bg-aqua text-white border-gray-dark hover:bg-aqua-light hover:border-aqua", @class]}
                       icon="headphones-lineawesome-solid"
                       title={@title || @for.title}
                       large={@large}
                       truncate={@truncate} />
    """
  end
end
