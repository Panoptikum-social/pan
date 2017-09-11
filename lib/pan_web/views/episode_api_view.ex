defmodule PanWeb.EpisodeApiView do
  use Pan.Web, :view
  use JaSerializer.PhoenixView
  alias PanWeb.Episode

  def type(_, _), do: "episode"

  location :episode_api_url
  attributes [:orig_link, :title, :publishing_date, :guid, :description, :shownotes,
              :payment_link_title, :payment_link_url, :deep_link, :duration, :subtitle, :summary,
              :like_count]


  has_one :podcast, serializer: PanWeb.PlainPodcastApiView, include: false
  has_many :chapters, serializer: PanWeb.PlainChapterApiView, include: false
  has_many :recommendations, serializer: PanWeb.PodcastRecommendationApiView, include: false
  has_many :enclosures, serializer: PanWeb.PlainEnclosureApiView, include: false
  has_many :gigs, serializer: PanWeb.PlainGigApiView, include: false
  has_many :contributors, serializer: PanWeb.PlainPersonaApiView, include: false

  def orig_link(episode) do
    episode.link
  end

  def like_count(episode) do
    Episode.likes(episode.id)
  end

  def episode_api_url(episode, conn) do
    episode_api_url(conn, :show, episode)
  end
end


defmodule PanWeb.PlainEpisodeApiView do
  use Pan.Web, :view
  use JaSerializer.PhoenixView

  def type(_, _), do: "episode"

  location :episode_api_url
  attributes [:orig_link, :title, :publishing_date, :description, :deep_link, :duration, :subtitle,
              :summary]

  def orig_link(episode) do
    episode.link
  end

  def episode_api_url(episode, conn) do
    episode_api_url(conn, :show, episode)
  end
end