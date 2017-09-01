defmodule Pan.AlternateFeedApiView do
  use Pan.Web, :view
  use JaSerializer.PhoenixView

  def type(_, _), do: "alternate_feed"

  location "https://panoptikum.io/jsonapi/alternate_feeds/:id"
  attributes [:title, :orig_url]

  has_one :feed, serializer: Pan.PlainFeedApiView, include: true

  def orig_url(alternate_feed) do
    alternate_feed.url
  end
end


defmodule Pan.PlainAlternateFeedApiView do
  use Pan.Web, :view
  use JaSerializer.PhoenixView

  def type(_, _), do: "alternate_feed"

  location "https://panoptikum.io/jsonapi/alternate_feeds/:id"
  attributes [:title, :orig_url]

  def orig_url(alternate_feed) do
    alternate_feed.url
  end
end
