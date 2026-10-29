defmodule PanWeb.Component.PodcastButton do
  use PanWeb, :html
  import PanWeb.ViewHelpers, only: [truncate_string: 2]
  alias PanWeb.Component.EntityLink
  alias PanWeb.Router.Helpers, as: Routes
  alias PanWeb.Endpoint

  attr :id, :integer, default: nil
  attr :title, :string, default: nil
  attr :large, :boolean, default: false
  attr :for, :map, default: nil
  attr :class, :string, default: nil
  attr :truncate, :boolean, default: false

  def render(assigns) do
    ~H"""
    <EntityLink.render
      to={Routes.podcast_frontend_path(Endpoint, :show, @id || @for.id)}
      id={@for && "podcast-button-#{@for.id}"}
      class={@class}
      icon="microphone"
      icon_class="text-podcast"
      title={truncate_string(@title || @for.title, 80)}
      large={@large}
      truncate={@truncate}
    />
    """
  end
end
