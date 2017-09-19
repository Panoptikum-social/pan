defmodule PanWeb.Api.FeedView do
  use Pan.Web, :view
  use JaSerializer.PhoenixView

  def type(_, _), do: "feed"

  location :location
  attributes [:self_link_title, :self_link_url, :next_page_url, :prev_page_url, :first_page_url,
              :last_page_url, :hub_link_url, :feed_generator]

  has_one :podcast,    serializer: PanWeb.Api.PlainPodcastView, include: true
  has_many :alternate_feeds, serializer: PanWeb.Api.PlainAlternateFeedView, include: true

  def location(feed, conn) do
    api_feed_url(conn, :show, feed)
  end
end


defmodule PanWeb.Api.PlainFeedView do
  use Pan.Web, :view
  use JaSerializer.PhoenixView

  def type(_, _), do: "feed"

  location :location
  attributes [:self_link_title, :self_link_url, :next_page_url, :prev_page_url, :first_page_url,
              :last_page_url, :hub_link_url, :feed_generator]

  def location(feed, conn) do
    api_feed_url(conn, :show, feed)
  end
end
