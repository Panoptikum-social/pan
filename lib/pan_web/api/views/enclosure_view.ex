defmodule PanWeb.Api.EnclosureView do
  use Pan.Web, :view
  use JaSerializer.PhoenixView

  def type(_, _), do: "enclosure"

  location :location
  attributes [:orig_url, :duration, :type, :guid]

  has_one :episode, serializer: PanWeb.Api.PlainEpisodeView, include: false

  def orig_url(alternate_feed) do
    alternate_feed.url
  end

  def duration(alternate_feed) do
    alternate_feed.length
  end

  def location(enclosure, conn) do
    enclosure_url(conn, :show, enclosure)
  end
end


defmodule PanWeb.Api.PlainEnclosureView do
  use Pan.Web, :view
  use JaSerializer.PhoenixView

  def type(_, _), do: "enclosure"

  location :location
  attributes [:orig_url, :duration, :type, :guid]

  def orig_url(alternate_feed) do
    alternate_feed.url
  end

  def duration(alternate_feed) do
    alternate_feed.length
  end

  def location(enclosure, conn) do
    enclosure_url(conn, :show, enclosure)
  end
end
