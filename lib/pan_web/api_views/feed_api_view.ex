defmodule PanWeb.FeedApiView do
  use Pan.Web, :view
  use JaSerializer.PhoenixView

  def type(_, _), do: "feed"

  location :feed_api_url
  attributes [:self_link_title, :self_link_url, :next_page_url, :prev_page_url, :first_page_url,
              :last_page_url, :hub_link_url, :feed_generator]

  has_one :podcast,    serializer: PanWeb.PlainPodcastApiView, include: true
  has_many :alternate_feeds, serializer: PanWeb.PlainAlternateFeedApiView, include: true

  def feed_api_url(feed, conn) do
    feed_api_url(conn, :show, feed)
  end
end


defmodule PanWeb.PlainFeedApiView do
  use Pan.Web, :view
  use JaSerializer.PhoenixView

  def type(_, _), do: "feed"

  location :feed_api_url
  attributes [:self_link_title, :self_link_url, :next_page_url, :prev_page_url, :first_page_url,
              :last_page_url, :hub_link_url, :feed_generator]

  def feed_api_url(feed, conn) do
    feed_api_url(conn, :show, feed)
  end
end
