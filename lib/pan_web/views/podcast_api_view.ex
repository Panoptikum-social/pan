defmodule PanWeb.PodcastApiView do
  use Pan.Web, :view
  use JaSerializer.PhoenixView
  alias PanWeb.Podcast

  def type(_, _), do: "podcast"

  location :podcast_api_url
  attributes [:title, :website, :description, :summary, :image_title, :image_url, :last_build_date,
              :payment_link_title, :payment_link_url, :explicit, :blocked, :update_paused,
              :update_intervall, :next_update, :retired, :unique_identifier, :follower_count,
              :like_count, :subscription_count, :latest_episode_publishing_date]

  has_many :episodes, serializer: PanWeb.PlainEpisodeApiView, include: false
  has_many :categories, serializer: PanWeb.PlainCategoryApiView, include: false
  has_many :languages, serializer: PanWeb.LanguageApiView, include: false
  has_many :languages, serializer: PanWeb.LanguageApiView, include: false
  has_many :engagements, serializer: PanWeb.PlainEngagmentApiView, include: false
  has_many :contributors, serializer: PanWeb.PlainPersonaApiView, include: false
  has_many :recommendations, serializer: PanWeb.PodcastRecommendationApiView, include: false
  has_many :feeds, serializer: PanWeb.PlainFeedApiView, include: false

  def follower_count(podcast) do
    Podcast.follows(podcast.id)
  end

  def like_count(podcast) do
    Podcast.likes(podcast.id)
  end

  def subscription_count(podcast) do
    Podcast.subscriptions(podcast.id)
  end

  def podcast_api_url(podcast, conn) do
    podcast_api_url(conn, :show, podcast)
  end

  def latest_episode_publishing_date(podcast) do
    Podcast.latest_episode_publishing_date(podcast.id)
  end
end


defmodule PanWeb.PlainPodcastApiView do
  use Pan.Web, :view
  use JaSerializer.PhoenixView

  def type(_, _), do: "podcast"

  location :podcast_api_url
  attributes [:title, :website, :description, :image_title, :image_url]

  def podcast_api_url(podcast, conn) do
    podcast_api_url(conn, :show, podcast)
  end
end
