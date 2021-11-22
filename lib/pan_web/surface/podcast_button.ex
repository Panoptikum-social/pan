defmodule PanWeb.Surface.PodcastButton do
  use Surface.Component
  alias PanWeb.Surface.LinkButton
  alias PanWeb.Router.Helpers, as: Routes

  prop(id, :integer, required: false)
  prop(title, :string, required: false)
  prop(for, :map, required: false)
  prop(class, :string, required: false)
  prop(truncate, :boolean, default: false)

  def render(assigns) do
    ~F"""
    <LinkButton to={Routes.podcast_frontend_path(@socket, :show, @id || @for.id)}
                class={"bg-white hover:bg-gray-lighter text-black border-gray", @class}
                icon="podcast-lineawesome-solid"
                title={@title || @for.title}
                truncate={@truncate} />
    """
  end
end
