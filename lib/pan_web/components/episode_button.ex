defmodule PanWeb.Component.EpisodeButton do
  use PanWeb, :html
  import PanWeb.ViewHelpers, only: [truncate_string: 2]
  alias PanWeb.Component.EntityLink
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
    <EntityLink.render
      to={Routes.episode_frontend_path(Endpoint, :show, @id || @for.id)}
      class={@class}
      icon="headphones"
      icon_class="text-episode"
      title={truncate_string(@title || @for.title, 80)}
      large={@large}
      truncate={@truncate}
    />
    """
  end
end
