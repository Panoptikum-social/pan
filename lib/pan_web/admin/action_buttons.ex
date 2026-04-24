defmodule PanWeb.Admin.ActionButtons do
  use PanWeb, :html

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

  alias PanWeb.Component.LinkButton
  import PanWeb.Router.Helpers

  attr :record, :map, default: nil
  attr :model, :atom, required: true
  attr :type, :atom, required: true

  def render(%{model: Image, value: :show} = assigns) do
    ~H"""
    <div class="m-2 flex space-x-4">
      <h3 class="text-xl">Preview</h3>
      <img src={"https://panoptikum.social#{@record.path}#{@record.filename}"} />
    </div>
    """
  end

  def render(%{model: Image, type: :index} = assigns) do
    ~H"""
    <div class="m-2 flex space-x-4">
      <LinkButton.render title="Cache missing images"
                         to={image_path(Endpoint, :cache_missing)}
                         class="btn-warning" />
      <LinkButton.render title="Remove duplicate images"
                         to={image_path(Endpoint, :remove_duplicates)}
                         class="btn-warning" />
      <LinkButton.render title="Upload new image"
                         to={image_path(Endpoint, :new)}
                         class="btn-warning" />
    </div>
    """
  end

  def render(%{model: Feed, type: :show} = assigns) do
    ~H"""
    <div class="m-2 flex space-x-4">
      <LinkButton.render title="Make primary"
                         to={feed_path(Endpoint, :make_only, @record)}
                         class="btn-warning"
                         method={:post} />
    </div>
    """
  end

  def render(%{model: User, type: :show} = assigns) do
    ~H"""
    <div class="m-2 flex space-x-4">
      <LinkButton.render title="Edit Password"
                         to={user_path(Endpoint, :edit_password, @record)}
                         class="btn-warning" />
      <LinkButton.render title="Unset Pro Date"
                         to={user_path(Endpoint, :unset_pro, @record)}
                         class="btn-error"
                         opts={[data: [confirm: "Are you sure?"]]} />
    </div>
    <div class="m-2 flex space-x-4 text-align-top">
      <span>no admin interface exists for</span>
      <LinkButton.render title="Push Subscriptions"
                         to="/admin/users/:user_id/category/:category_id/push_subscriptions"
                         class="btn-primary" />
    </div>
    """
  end

  def render(%{model: User, type: :index} = assigns) do
    ~H"""
    <div class="m-2 flex space-x-4">
      <LinkButton.render title="Merge Users"
                         to={user_path(Endpoint, :merge)}
                         class="btn-ghost" />
    </div>
    """
  end

  def render(%{model: Category, type: :index} = assigns) do
    ~H"""
    <div class="m-2 flex space-x-4">
      <LinkButton.render title="Merge Categories"
                         to={category_path(Endpoint, :merge)}
                         class="btn-ghost" />
    </div>
    """
  end

  def render(%{model: Invoice, type: :index} = assigns) do
    ~H"""
    <div class="m-2 flex space-x-4">
      <LinkButton.render title="List of Invoices"
                         to={invoice_path(Endpoint, :index)}
                         class="btn-ghost" />
    </div>
    """
  end

  def render(%{model: Opml, type: :index} = assigns) do
    ~H"""
    <div class="m-2 flex space-x-4">
      <LinkButton.render title="List of OPMLs"
                         to={opml_path(Endpoint, :index)}
                         class="btn-ghost" />
    </div>
    """
  end

  def render(%{model: FeedBacklog, type: :index} = assigns) do
    ~H"""
    <div class="m-2 flex space-x-4">
      <LinkButton.render title="List of BacklogFeeds"
                         to={feed_backlog_path(Endpoint, :index)}
                         class="btn-ghost" />
      <LinkButton.render title="Import 100"
                         to={feed_backlog_path(Endpoint, :import_100)}
                         class="btn-warning" />
      <LinkButton.render title="Subscribe All"
                         to={feed_backlog_path(Endpoint, :subscribe)}
                         class="btn-warning" />
      <LinkButton.render title="Subscribe 50"
                         to={feed_backlog_path(Endpoint, :subscribe50)}
                         class="btn-warning" />
      <LinkButton.render title="Delete All"
                         to={feed_backlog_path(Endpoint, :delete_all)}
                         class="btn-error"
                         opts={[method: :delete, data: [confirm: "Are you sure?"]]} />
    </div>
    """
  end

  def render(%{model: Podcast, type: :show} = assigns) do
    ~H"""
    <div class="m-2 flex space-x-4">
      <LinkButton.render title="Pause"
                         to={podcast_path(Endpoint, :pause, @record)}
                         class="btn-warning" />
      <LinkButton.render title="Touch"
                         to={podcast_path(Endpoint, :touch, @record)}
                         class="btn-info" />
      <LinkButton.render title="Delta import"
                         to={podcast_path(Endpoint, :delta_import, @record)}
                         class="btn-primary" />
      <LinkButton.render title="Forced delta import"
                         to={podcast_path(Endpoint, :forced_delta_import, @record)}
                         class="btn-primary" />
      <LinkButton.render title="Delete"
                         to={podcast_path(Endpoint, :delete, @record)}
                         class="btn-error"
                         method={:delete}
                         opts={[data: [confirm: "Are you sure?"]]} />
      <LinkButton.render title="Contributor import"
                         to={podcast_path(Endpoint, :contributor_import, @record)}
                         class="btn-success" />
      <LinkButton.render title="Update from feed"
                         to={podcast_path(Endpoint, :update_from_feed, @record)}
                         class="btn-primary" />
      <LinkButton.render title="Update counters"
                         to={podcast_path(Endpoint, :update_counters, @record)}
                         class="btn-warning" />
      <LinkButton.render title="Fix owner"
                         to={podcast_path(Endpoint, :fix_owner, @record)}
                         class="btn-warning" />
    </div>
    """
  end

  def render(%{model: Podcast, type: :index} = assigns) do
    ~H"""
    <div class="m-2 flex space-x-4 items-center">
      <LinkButton.render title="Duplicates"
                         to={podcast_path(Endpoint, :duplicates)}
                         class="btn-ghost" />
      <LinkButton.render title="Orphans"
                         to={podcast_path(Endpoint, :orphans)}
                         class="btn-ghost" />
      <LinkButton.render title="Stale"
                         to={podcast_path(Endpoint, :stale)}
                         class="btn-ghost" />
      <LinkButton.render title="Retirement"
                         to={podcast_path(Endpoint, :retirement)}
                         class="btn-ghost" />
      <LinkButton.render title="Update missing counters"
                         to={podcast_path(Endpoint, :update_missing_counters)}
                         class="btn-warning" />
      <LinkButton.render title="Update all counters"
                         to={podcast_path(Endpoint, :update_all_counters)}
                         class="bg-danger hover:bg-danger-dark border-gray" />
      <LinkButton.render title="Fix languages"
                         to={podcast_path(Endpoint, :fix_languages)}
                         class="btn-warning" />
    </div>
    """
  end

  def render(%{model: Episode, type: :index} = assigns) do
    ~H"""
    <div class="m-2 flex space-x-4 items-center">
      <LinkButton.render title="Remove duplicates"
                         to={episode_path(Endpoint, :remove_duplicates)}
                         class="btn-ghost" />
      <LinkButton.render title="Remove javascript from shownotes"
                         to={episode_path(Endpoint, :remove_javascript_from_shownotes)}
                         class="btn-warning" />
    </div>
    """
  end

  def render(%{model: Persona, type: :index} = assigns) do
    ~H"""
    <div class="m-2 flex space-x-4 items-center">
      <LinkButton.render title="Merge candidates"
                         to={persona_path(Endpoint, :merge_candidates)}
                         class="btn-ghost" />
    </div>
    """
  end

  def render(assigns) do
    ~H"""
    <div class="m-4">
      No action Buttons for {@model} defined.
    </div>
    """
  end
end
