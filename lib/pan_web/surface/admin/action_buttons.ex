defmodule PanWeb.Surface.Admin.ActionButtons do
  use Surface.Component
  alias PanWeb.{Endpoint, Podcast}
  alias PanWeb.Surface.LinkButton
  import PanWeb.Router.Helpers

  prop(record, :map, required: true)
  prop(model, :module, required: true)

  def render(%{model: Podcast} = assigns) do
    ~F"""
    <div class="m-4">
      <LinkButton title="Pause"
                  to={podcast_path(Endpoint, :pause, @record)}
                  large
                  class="bg-warning hover:bg-warning-dark text-white border-gray" />
    </div>
    """
  end

  def render(assigns) do
    ~F"""
    <div class="m-4">
      No action Buttons for {@model} defined.
    </div>
    """
  end
end
