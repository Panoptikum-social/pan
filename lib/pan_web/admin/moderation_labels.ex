defmodule PanWeb.Admin.ModerationLabels do
  @moduledoc """
  Translated labels for the fields moderators see: the column headers of the
  moderation grids (podcasts, episodes, feeds) and the fields of their edit
  forms (#617, #621). Fields without a label of their own fall back to the
  humanized field name, as on the admin pages.
  """
  use Gettext, backend: PanWeb.Gettext

  alias PanWeb.Admin.Naming

  @doc "Column/field definitions for `fields` of `model`, as the grids and RecordForm expect them."
  def columns(model, fields) do
    Enum.map(fields, fn field ->
      %{
        field: field,
        label: label(field),
        type: Naming.type_of_field(model, field),
        searchable: true,
        sortable: true
      }
    end)
  end

  def label(:id), do: dgettext("moderation", "ID")
  def label(:title), do: dgettext("moderation", "Title")
  def label(:website), do: dgettext("moderation", "Website")
  def label(:link), do: dgettext("moderation", "Link")
  def label(:deep_link), do: dgettext("moderation", "Deep link")
  def label(:description), do: dgettext("moderation", "Description")
  def label(:summary), do: dgettext("moderation", "Summary")
  def label(:subtitle), do: dgettext("moderation", "Subtitle")
  def label(:shownotes), do: dgettext("moderation", "Shownotes")
  def label(:image_title), do: dgettext("moderation", "Image title")
  def label(:image_url), do: dgettext("moderation", "Image URL")
  def label(:payment_link_title), do: dgettext("moderation", "Payment link title")
  def label(:payment_link_url), do: dgettext("moderation", "Payment link URL")
  def label(:explicit), do: dgettext("moderation", "Explicit")
  def label(:blocked), do: dgettext("moderation", "Blocked")
  def label(:update_paused), do: dgettext("moderation", "Update paused")
  def label(:update_intervall), do: dgettext("moderation", "Update interval (hours)")
  def label(:next_update), do: dgettext("moderation", "Next update")
  def label(:next_podcast_update), do: dgettext("moderation", "Next podcast update")
  def label(:retired), do: dgettext("moderation", "Retired")
  def label(:failure_count), do: dgettext("moderation", "Failures in a row")
  def label(:unique_identifier), do: dgettext("moderation", "Unique identifier")
  def label(:episodes_count), do: dgettext("moderation", "Episodes")
  def label(:followers_count), do: dgettext("moderation", "Followers")
  def label(:likes_count), do: dgettext("moderation", "Likes")
  def label(:subscriptions_count), do: dgettext("moderation", "Subscriptions")
  def label(:last_build_date), do: dgettext("moderation", "Last build date")

  def label(:latest_episode_publishing_date),
    do: dgettext("moderation", "Latest episode published")

  def label(:publication_frequency), do: dgettext("moderation", "Publication frequency (days)")
  def label(:manually_updated_at), do: dgettext("moderation", "Manually updated")
  def label(:full_text), do: dgettext("moderation", "Full text indexed")
  def label(:thumbnailed), do: dgettext("moderation", "Thumbnail created")
  def label(:last_error_message), do: dgettext("moderation", "Last error")
  def label(:last_error_occured), do: dgettext("moderation", "Last error at")
  def label(:publishing_date), do: dgettext("moderation", "Publishing date")
  def label(:guid), do: dgettext("moderation", "GUID")
  def label(:duration), do: dgettext("moderation", "Duration")
  def label(:self_link_title), do: dgettext("moderation", "Feed title")
  def label(:self_link_url), do: dgettext("moderation", "Feed URL")
  def label(:next_page_url), do: dgettext("moderation", "Next page URL")
  def label(:prev_page_url), do: dgettext("moderation", "Previous page URL")
  def label(:first_page_url), do: dgettext("moderation", "First page URL")
  def label(:last_page_url), do: dgettext("moderation", "Last page URL")
  def label(:hub_link_url), do: dgettext("moderation", "Hub URL")
  def label(:feed_generator), do: dgettext("moderation", "Feed generator")
  def label(:etag), do: dgettext("moderation", "ETag")
  def label(:last_modified), do: dgettext("moderation", "Last modified")
  def label(:trust_last_modified), do: dgettext("moderation", "Trust Last-Modified")
  def label(:no_headers_available), do: dgettext("moderation", "No caching headers")
  def label(:hash), do: dgettext("moderation", "Hash")
  def label(:inserted_at), do: dgettext("moderation", "Created")
  def label(:updated_at), do: dgettext("moderation", "Updated")
  def label(field), do: Naming.title_from_field(field)
end
