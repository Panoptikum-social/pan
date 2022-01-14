defmodule PanWeb.Surface.Admin.ActionButtons do
  use Surface.Component
  alias PanWeb.{Endpoint, Podcast}
  alias PanWeb.Surface.LinkButton
  import PanWeb.Router.Helpers

  prop(record, :map, required: true)
  prop(model, :module, required: true)

  def render(%{model: Podcast} = assigns) do
    ~F"""
    <div class="m-4 flex space-x-4">
      <LinkButton title="Pause"
                  to={podcast_path(Endpoint, :pause, @record)}
                  large
                  class="bg-warning hover:bg-warning-dark text-white border-gray" />

      <LinkButton title="Touch"
                  to={podcast_path(Endpoint, :touch, @record)}
                  large
                  class="bg-info hover:bg-info-dark text-white border-gray" />

      <LinkButton title="Delta import"
                  to={podcast_path(Endpoint, :delta_import, @record)}
                  large
                  class="bg-primary hover:bg-primary-dark text-white border-gray" />

      <LinkButton title="Forced delta import"
                  to={podcast_path(Endpoint, :forced_delta_import, @record)}
                  large
                  class="bg-primary hover:bg-primary-dark text-white border-gray" />

      <LinkButton title="Delete"
                  to={podcast_path(Endpoint, :delete, @record)}
                  large
                  class="bg-danger hover:bg-danger-dark text-white border-gray"
                  method={:delete}
                  opts={data: [confirm: "Are you sure?"]} />

      <LinkButton title="Contributor import"
                  to={podcast_path(Endpoint, :contributor_import, @record)}
                  large
                  class="bg-success hover:bg-success-dark text-white border-gray" />

      <LinkButton title="Update from feed"
                  to={podcast_path(Endpoint, :update_from_feed, @record)}
                  large
                  class="bg-primary hover:bg-primary-dark text-white border-gray" />
    </div>
    <div class="m-4 flex space-x-4 items-center">
      <h3 class="text-xl">Lists</h3>
      <LinkButton title="Stale"
                  to={podcast_path(Endpoint, :stale)}
                  large
                  class="bg-white hover:bg-gray-light border-gray" />

      <LinkButton title="Orphans"
                  to={podcast_path(Endpoint, :orphans)}
                  large
                  class="bg-white hover:bg-gray-light border-gray" />

      <LinkButton title="Retirement"
                  to={podcast_path(Endpoint, :retirement)}
                  large
                  class="bg-white hover:bg-gray-light border-gray" />
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
