defmodule PanWeb.Api.EpisodeView do
  use Pan.Web, :view
  use JaSerializer.PhoenixView
  alias PanWeb.Episode

  def type(_, _), do: "episode"

  location :location
  attributes [:orig_link, :title, :publishing_date, :guid, :description, :shownotes,
              :payment_link_title, :payment_link_url, :deep_link, :duration, :subtitle, :summary,
              :like_count, :image_title, :image_url]


  has_one :podcast, serializer: PanWeb.Api.PlainPodcastView, include: false
  has_many :chapters, serializer: PanWeb.Api.PlainChapterView, include: false
  has_many :recommendations, serializer: PanWeb.Api.PodcastRecommendationView, include: false
  has_many :enclosures, serializer: PanWeb.Api.PlainEnclosureView, include: false
  has_many :gigs, serializer: PanWeb.Api.PlainGigView, include: false
  has_many :contributors, serializer: PanWeb.Api.PlainPersonaView, include: false

  def orig_link(episode) do
    episode.link
  end

  def like_count(episode) do
    Episode.likes(episode.id)
  end

  def location(episode, conn) do
    api_episode_url(conn, :show, episode)
  end
end


defmodule PanWeb.Api.PlainEpisodeView do
  use Pan.Web, :view
  use JaSerializer.PhoenixView

  def type(_, _), do: "episode"

  location :location
  attributes [:orig_link, :title, :publishing_date, :description, :deep_link, :duration, :subtitle,
              :summary, :image_title, :image_url]

  has_many :enclosures, serializer: PanWeb.Api.PlainEnclosureView, include: false

  def orig_link(episode) do
    episode.link
  end

  def location(episode, conn) do
    api_episode_url(conn, :show, episode)
  end
end
