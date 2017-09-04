defmodule Pan.AlternateFeedApiView do
  use Pan.Web, :view
  use JaSerializer.PhoenixView

  def type(_, _), do: "alternate_feed"

  location :alternate_feed_api_url
  attributes [:title, :orig_url]

  has_one :feed, serializer: Pan.PlainFeedApiView, include: true

  def orig_url(alternate_feed) do
    alternate_feed.url
  end

  def alternate_feed_api_url(alternate_feed, conn) do
    alternate_feed_api_url(conn, :show, alternate_feed)
  end
end


defmodule Pan.PlainAlternateFeedApiView do
  use Pan.Web, :view
  use JaSerializer.PhoenixView

  def type(_, _), do: "alternate_feed"

  location :alternate_feed_api_url
  attributes [:title, :orig_url]

  def orig_url(alternate_feed) do
    alternate_feed.url
  end

  def alternate_feed_api_url(alternate_feed, conn) do
    alternate_feed_api_url(conn, :show, alternate_feed)
  end
end
