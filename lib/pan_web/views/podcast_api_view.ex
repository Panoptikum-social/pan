defmodule PanWeb.PodcastApiView do
  use Pan.Web, :view
  use JaSerializer.PhoenixView

  def type(_, _), do: "podcast"

  location :podcast_api_url
  attributes [:title, :website, :description, :summary, :image_title, :image_url, :last_build_date,
              :payment_link_title, :payment_link_url, :explicit, :blocked, :update_paused,
              :update_intervall, :next_update, :retired, :unique_identifier, :episodes_count,
              :followers_count, :likes_count, :subscriptions_count, :latest_episode_publishing_date,
              :publication_frequency]

  has_many :episodes, serializer: PanWeb.PlainEpisodeApiView, include: false
  has_many :categories, serializer: PanWeb.PlainCategoryApiView, include: false
  has_many :languages, serializer: PanWeb.LanguageApiView, include: false
  has_many :languages, serializer: PanWeb.LanguageApiView, include: false
  has_many :engagements, serializer: PanWeb.PlainEngagmentApiView, include: false
  has_many :contributors, serializer: PanWeb.PlainPersonaApiView, include: false
  has_many :recommendations, serializer: PanWeb.PodcastRecommendationApiView, include: false
  has_many :feeds, serializer: PanWeb.PlainFeedApiView, include: false

  def podcast_api_url(podcast, conn) do
    podcast_api_url(conn, :show, podcast)
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
