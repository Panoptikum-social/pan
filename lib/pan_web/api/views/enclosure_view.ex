defmodule PanWeb.Api.EnclosureView do
  use PanWeb, :view
  use JaSerializer.PhoenixView

  location(:location)
  attributes([:orig_url, :file_size, :enclosure_type, :guid, :mime_type])

  def type(_, _), do: "enclosure"

  has_one(:episode, serializer: PanWeb.Api.PlainEpisodeView, include: false)

  def orig_url(enclosure) do
    enclosure.url
  end

  def mime_type(enclosure) do
    enclosure.type
  end

  def file_size(enclosure) do
    enclosure.length
  end

  def location(enclosure, conn) do
    api_enclosure_url(conn, :show, enclosure)
  end

  def enclosure_type(enclosure) do
    enclosure.type
  end
end

defmodule PanWeb.Api.PlainEnclosureView do
  use PanWeb, :view
  use JaSerializer.PhoenixView

  location(:location)
  attributes([:orig_url, :file_size, :enclosure_type, :guid, :mime_type])

  def type(_, _), do: "enclosure"

  def orig_url(enclosure) do
    enclosure.url
  end

  def file_size(enclosure) do
    enclosure.length
  end

  def mime_type(enclosure) do
    enclosure.type
  end

  def location(enclosure, conn) do
    api_enclosure_url(conn, :show, enclosure)
  end

  def enclosure_type(enclosure) do
    enclosure.type
  end
end
