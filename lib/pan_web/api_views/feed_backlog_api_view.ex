defmodule PanWeb.FeedBacklogApiView do
  use Pan.Web, :view
  use JaSerializer.PhoenixView

  def type(_, _), do: "feed_backlog"

  location :feed_backlog_api_url
  attributes [:orig_url, :feed_generator, :in_progress]

  has_one :user, serializer: PanWeb.PlainUserApiView, include: false

  def orig_url(feed_backlog) do
    feed_backlog.url
  end

  def feed_backlog_api_url(feed_backlog, conn) do
    feed_backlog_api_url(conn, :show, feed_backlog)
  end
end
