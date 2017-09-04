defmodule Pan.EnclosureApiView do
  use Pan.Web, :view
  use JaSerializer.PhoenixView

  def type(_, _), do: "enclosure"

  location :enclosure_api_url
  attributes [:orig_url, :duration, :type, :guid]

  has_one :episode, serializer: Pan.PlainEpisodeApiView, include: false

  def orig_url(alternate_feed) do
    alternate_feed.url
  end

  def duration(alternate_feed) do
    alternate_feed.length
  end

  def enclosure_api_url(enclosure, conn) do
    enclosure_api_url(conn, :show, enclosure)
  end
end


defmodule Pan.PlainEnclosureApiView do
  use Pan.Web, :view
  use JaSerializer.PhoenixView

  def type(_, _), do: "enclosure"

  location :enclosure_api_url
  attributes [:orig_url, :duration, :type, :guid]

  def orig_url(alternate_feed) do
    alternate_feed.url
  end

  def duration(alternate_feed) do
    alternate_feed.length
  end

  def enclosure_api_url(enclosure, conn) do
    enclosure_api_url(conn, :show, enclosure)
  end
end
