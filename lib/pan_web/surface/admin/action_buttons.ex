defmodule PanWeb.Surface.Admin.ActionButtons do
  use Surface.Component

  alias PanWeb.{
    Endpoint,
    Podcast,
    User,
    Feed,
    Image,
    Episode,
    Persona,
    Category,
    Invoice,
    Opml,
    FeedBacklog
  }

  alias PanWeb.Surface.LinkButton
  import PanWeb.Router.Helpers

  prop(record, :map, required: false)
  prop(model, :module, required: true)
  prop(type, :atom, required: true, values: [:show, :index])

  def render(%{model: Image, value: :show} = assigns) do
    ~F"""
    <div class="m-2 flex space-x-4">
      <h3 class="text-xl">Preview</h3>
      <img src={"https://panoptikum.io#{@record.path}#{@record.filename}"} />
    </div>
    """
  end

  def render(%{model: Image, type: :index} = assigns) do
    ~F"""
    <div class="m-2 flex space-x-4">
      <LinkButton title="Cache missing images"
                  to={image_path(Endpoint, :cache_missing)}
                  class="bg-warning hover:bg-warning-dark border-gray" />
      <LinkButton title="Remove duplicate images"
                  to={image_path(Endpoint, :remove_duplicates)}
                  class="bg-warning hover:bg-warning-dark border-gray" />
      <LinkButton title="Upload new image"
                  to={image_path(Endpoint, :new)}
                  class="bg-warning hover:bg-warning-dark border-gray" />
    </div>
    """
  end

  def render(%{model: Feed, type: :show} = assigns) do
    ~F"""
    <div class="m-2 flex space-x-4">
      <LinkButton title="Make primary"
                  to={feed_path(Endpoint, :make_only, @record)}
                  class="bg-warning hover:bg-warning-dark text-white border-gray"
                  method={:post} />
    </div>
    """
  end

  def render(%{model: User, type: :show} = assigns) do
    ~F"""
    <div class="m-2 flex space-x-4">
      <LinkButton title="Edit Password"
                  to={user_path(Endpoint, :edit_password, @record)}
                  class="bg-warning hover:bg-warning-dark border-gray" />
      <LinkButton title="Unset Pro Date"
                  to={user_path(Endpoint, :unset_pro, @record)}
                  class="bg-danger hover:bg-danger-dark border-gray text-white"
                  opts={data: [confirm: "Are you sure?"]} />

    </div>
    <div class="m-2 flex space-x-4 text-align-top">
      <span>no admin interface exists for</span>
      <LinkButton title="Push Subscriptions"
                  to="/admin/users/:user_id/category/:category_id/push_subscriptions"
                  class="bg-mint-light hover:bg-mint border-gray" />
    </div>
    """
  end

  def render(%{model: User, type: :index} = assigns) do
    ~F"""
    <div class="m-2 flex space-x-4">
      <LinkButton title="Merge Users"
                  to={user_path(Endpoint, :merge)}
                  class="bg-white hover:bg-gray-light border-gray" />
    </div>
    """
  end

  def render(%{model: Category, type: :index} = assigns) do
    ~F"""
    <div class="m-2 flex space-x-4">
      <LinkButton title="Merge Categories"
                  to={category_path(Endpoint, :merge)}
                  class="bg-white hover:bg-gray-light border-gray" />
    </div>
    """
  end

  def render(%{model: Invoice, type: :index} = assigns) do
    ~F"""
    <div class="m-2 flex space-x-4">
      <LinkButton title="List of Invoices"
                  to={invoice_path(Endpoint, :index)}
                  class="bg-white hover:bg-gray-light border-gray" />
    </div>
    """
  end

  def render(%{model: Opml, type: :index} = assigns) do
    ~F"""
    <div class="m-2 flex space-x-4">
      <LinkButton title="List of OPMLs"
                  to={opml_path(Endpoint, :index)}
                  class="bg-white hover:bg-gray-light border-gray" />
    </div>
    """
  end

  def render(%{model: FeedBacklog, type: :index} = assigns) do
    ~F"""
    <div class="m-2 flex space-x-4">
      <LinkButton title="List of BacklogFeeds"
                  to={feed_backlog_path(Endpoint, :index)}
                  class="bg-white hover:bg-gray-light border-gray" />
      <LinkButton title="Import 100"
                  to={feed_backlog_path(Endpoint, :import_100)}
                  class="bg-warning hover:bg-warning-dark border-gray" />
      <LinkButton title="Subscribe All"
                  to={feed_backlog_path(Endpoint, :subscribe)}
                  class="bg-warning hover:bg-warning-dark border-gray" />
      <LinkButton title="Subscribe 50"
                  to={feed_backlog_path(Endpoint, :subscribe50)}
                  class="bg-warning hover:bg-warning-dark border-gray" />
      <LinkButton title="Delete All"
                  to={feed_backlog_path(Endpoint, :delete_all)}
                  class="bg-danger hover:bg-danger-dark border-gray text-white"
                  opts={method: :delete,
                        data: [confirm: "Are you sure?"]} />
    </div>
    """
  end

  def render(%{model: Podcast, type: :show} = assigns) do
    ~F"""
    <div class="m-2 flex space-x-4">
      <LinkButton title="Pause"
                  to={podcast_path(Endpoint, :pause, @record)}
                  class="bg-warning hover:bg-warning-dark border-gray" />
      <LinkButton title="Touch"
                  to={podcast_path(Endpoint, :touch, @record)}
                  class="bg-info hover:bg-info-dark text-white border-gray" />
      <LinkButton title="Delta import"
                  to={podcast_path(Endpoint, :delta_import, @record)}
                  class="bg-primary hover:bg-primary-dark text-white border-gray" />
      <LinkButton title="Forced delta import"
                  to={podcast_path(Endpoint, :forced_delta_import, @record)}
                  class="bg-primary hover:bg-primary-dark text-white border-gray" />
      <LinkButton title="Delete"
                  to={podcast_path(Endpoint, :delete, @record)}
                  class="bg-danger hover:bg-danger-dark text-white border-gray"
                  method={:delete}
                  opts={data: [confirm: "Are you sure?"]} />
      <LinkButton title="Contributor import"
                  to={podcast_path(Endpoint, :contributor_import, @record)}
                  class="bg-success hover:bg-success-dark text-white border-gray" />
      <LinkButton title="Update from feed"
                  to={podcast_path(Endpoint, :update_from_feed, @record)}
                  class="bg-primary hover:bg-primary-dark text-white border-gray" />
      <LinkButton title="Update counters"
                  to={podcast_path(Endpoint, :update_counters, @record)}
                  class="bg-warning hover:bg-warning-dark border-gray" />
      <LinkButton title="Fix owner"
                  to={podcast_path(Endpoint, :fix_owner, @record)}
                  class="bg-warning hover:bg-warning-dark border-gray" />
    </div>
    """
  end

  def render(%{model: Podcast, type: :index} = assigns) do
    ~F"""
    <div class="m-2 flex space-x-4 items-center">
      <LinkButton title="Duplicates"
                  to={podcast_path(Endpoint, :duplicates)}
                  class="bg-white hover:bg-gray-light border-gray" />
      <LinkButton title="Orphans"
                  to={podcast_path(Endpoint, :orphans)}
                  class="bg-white hover:bg-gray-light border-gray" />
      <LinkButton title="Stale"
                  to={podcast_path(Endpoint, :stale)}
                  class="bg-white hover:bg-gray-light border-gray" />
      <LinkButton title="Retirement"
                  to={podcast_path(Endpoint, :retirement)}
                  class="bg-white hover:bg-gray-light border-gray" />
      <LinkButton title="Update missing counters"
                  to={podcast_path(Endpoint, :update_missing_counters)}
                  class="bg-warning hover:bg-warning-dark border-gray" />
      <LinkButton title="Update all counters"
                  to={podcast_path(Endpoint, :update_all_counters)}
                  class="bg-danger hover:bg-danger-dark border-gray" />
      <LinkButton title="Fix languages"
                  to={podcast_path(Endpoint, :fix_languages)}
                  class="bg-warning hover:bg-warning-dark border-gray" />
    </div>
    """
  end

  def render(%{model: Episode, type: :index} = assigns) do
    ~F"""
    <div class="m-2 flex space-x-4 items-center">
      <LinkButton title="Remove duplicates"
                  to={episode_path(Endpoint, :remove_duplicates)}
                  class="bg-white hover:bg-gray-light border-gray" />
      <LinkButton title="Remove javascript from shownotes"
                  to={episode_path(Endpoint, :remove_javascript_from_shownotes)}
                  class="bg-warning hover:bg-warning-dark border-gray" />
    </div>
    """
  end

  def render(%{model: Persona, type: :index} = assigns) do
    ~F"""
    <div class="m-2 flex space-x-4 items-center">
      <LinkButton title="Merge candidates"
                  to={persona_path(Endpoint, :merge_candidates)}
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
