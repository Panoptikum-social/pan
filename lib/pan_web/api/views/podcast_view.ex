defmodule PanWeb.Api.PodcastView do
  use Pan.Web, :view
  use JaSerializer.PhoenixView

  def type(_, _), do: "podcast"

  location(:location)

  attributes([
    :title,
    :website,
    :description,
    :summary,
    :image_title,
    :orig_image_url,
    :last_build_date,
    :payment_link_title,
    :payment_link_url,
    :explicit,
    :blocked,
    :update_paused,
    :update_intervall,
    :next_update,
    :retired,
    :unique_identifier,
    :episodes_count,
    :followers_count,
    :likes_count,
    :subscriptions_count,
    :latest_episode_publishing_date,
    :publication_frequency,
    :manually_updated_at,
    :full_text,
    :last_error_message,
    :last_error_occured
  ])

  has_many(:episodes, serializer: PanWeb.Api.PlainEpisodeView, include: false)
  has_many(:categories, serializer: PanWeb.Api.PlainCategoryView, include: false)
  has_many(:languages, serializer: PanWeb.Api.LanguageView, include: false)
  has_many(:languages, serializer: PanWeb.Api.LanguageView, include: false)
  has_many(:engagements, serializer: PanWeb.Api.PlainEngagmentView, include: false)
  has_many(:contributors, serializer: PanWeb.Api.PlainPersonaView, include: false)
  has_many(:recommendations, serializer: PanWeb.Api.PodcastRecommendationView, include: false)
  has_many(:feeds, serializer: PanWeb.Api.PlainFeedView, include: false)

  def location(podcast, conn) do
    api_podcast_url(conn, :show, podcast)
  end

  def orig_image_url(podcast, _conn) do
    podcast.image_url
  end
end

defmodule PanWeb.Api.PlainPodcastView do
  use Pan.Web, :view
  use JaSerializer.PhoenixView

  def type(_, _), do: "podcast"

  location(:location)

  attributes([
    :title,
    :website,
    :description,
    :image_title,
    :orig_image_url,
    :latest_episode_publishing_date
  ])

  def location(podcast, conn) do
    api_podcast_url(conn, :show, podcast)
  end

  def orig_image_url(podcast, _conn) do
    podcast.image_url
  end
end
