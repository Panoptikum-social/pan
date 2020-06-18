defmodule PanWeb.Api.AlternateFeedView do
  use Pan.Web, :view
  use JaSerializer.PhoenixView

  def type(_, _), do: "alternate_feed"

  location(:location)
  attributes([:title, :orig_url])

  has_one(:feed, serializer: PanWeb.Api.PlainFeedView, include: true)

  def orig_url(alternate_feed) do
    alternate_feed.url
  end

  def location(alternate_feed, conn) do
    api_alternate_feed_url(conn, :show, alternate_feed)
  end
end

defmodule PanWeb.Api.PlainAlternateFeedView do
  use Pan.Web, :view
  use JaSerializer.PhoenixView

  def type(_, _), do: "alternate_feed"

  location(:location)
  attributes([:title, :orig_url])

  def orig_url(alternate_feed) do
    alternate_feed.url
  end

  def location(alternate_feed, conn) do
    api_alternate_feed_url(conn, :show, alternate_feed)
  end
end
