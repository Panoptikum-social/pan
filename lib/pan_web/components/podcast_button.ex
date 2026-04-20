defmodule PanWeb.Component.PodcastButton do
  use PanWeb, :html
  alias PanWeb.Component.LinkButton
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
    <LinkButton.render to={Routes.podcast_frontend_path(Endpoint, :show, @id || @for.id)}
                       id={@for && "podcast-button-#{@for.id}"}
                       class={["bg-white hover:bg-gray-lighter text-black border-gray", @class]}
                       icon="podcast-lineawesome-solid"
                       title={@title || @for.title}
                       large={@large}
                       truncate={@truncate} />
    """
  end
end
