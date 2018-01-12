defmodule PanWeb.Api.EnclosureView do
  use Pan.Web, :view
  use JaSerializer.PhoenixView

  def type(_, _), do: "enclosure"

  location :location
  attributes [:orig_url, :duration, :type, :guid, :mime_type]

  has_one :episode, serializer: PanWeb.Api.PlainEpisodeView, include: false

  def orig_url(enclosure) do
    enclosure.url
  end

  def mime_type(enclosure) do
    enclosure.type
  end

  def duration(enclosure) do
    enclosure.length
  end

  def location(enclosure, conn) do
    api_enclosure_url(conn, :show, enclosure)
  end
end


defmodule PanWeb.Api.PlainEnclosureView do
  use Pan.Web, :view
  use JaSerializer.PhoenixView

  def type(_, _), do: "enclosure"

  location :location
  attributes [:orig_url, :duration, :type, :guid, :mime_type]

  def orig_url(alternate_feed) do
    alternate_feed.url
  end

  def duration(alternate_feed) do
    alternate_feed.length
  end

  def mime_type(enclosure) do
    enclosure.type
  end

  def location(enclosure, conn) do
    api_enclosure_url(conn, :show, enclosure)
  end
end
