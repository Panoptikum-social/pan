defmodule PanWeb.Surface.Admin.ActionButtons do
  use Surface.Component
  alias PanWeb.{Endpoint, Podcast, User, Feed, Image}
  alias PanWeb.Surface.LinkButton
  import PanWeb.Router.Helpers

  prop(record, :map, required: true)
  prop(model, :module, required: true)

  def render(%{model: Image} = assigns) do
    ~F"""
    <div class="m-4 flex space-x-4">
      <h3 class="text-xl">Preview</h3>
      <img src={"https://panoptikum.io#{@record.path}#{@record.filename}"} />
    </div>
    """
  end

  def render(%{model: Feed} = assigns) do
    ~F"""
    <div class="m-4 flex space-x-4">
      <LinkButton title="Make primary"
                  to={feed_path(Endpoint, :make_only, @record)}
                  large
                  class="bg-warning hover:bg-warning-dark text-white border-gray"
                  method={:post} />
    </div>
    """
  end

  def render(%{model: User} = assigns) do
    ~F"""
    <div class="m-4 flex space-x-4">
      <LinkButton title="Edit Password"
                  to={user_path(Endpoint, :edit_password, @record)}
                  large
                  class="bg-warning hover:bg-warning-dark text-white border-gray" />
    </div>
    """
  end

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

      <LinkButton title="Update counters"
                  to={podcast_path(Endpoint, :update_counters, @record)}
                  large
                  class="bg-warning hover:bg-warning-dark text-white border-gray" />
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

      <LinkButton title="Update missing counters"
                  to={podcast_path(Endpoint, :update_missing_counters)}
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
