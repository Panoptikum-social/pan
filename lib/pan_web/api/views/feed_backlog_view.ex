defmodule PanWeb.Api.FeedBacklogView do
  use Pan.Web, :view
  use JaSerializer.PhoenixView

  def type(_, _), do: "feed_backlog"

  location :location
  attributes [:orig_url, :feed_generator, :in_progress]

  has_one :user, serializer: PanWeb.Api.PlainUserView, include: false

  def orig_url(feed_backlog) do
    feed_backlog.url
  end

  def location(feed_backlog, conn) do
    api_feed_backlog_url(conn, :show, feed_backlog)
  end
end
