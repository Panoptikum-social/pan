defmodule PanWeb.Api.EpisodeView do
  use Pan.Web, :view
  use JaSerializer.PhoenixView
  alias PanWeb.Episode

  def type(_, _), do: "episode"

  location :location
  attributes [:orig_link, :title, :publishing_date, :guid, :description, :shownotes,
              :payment_link_title, :payment_link_url, :deep_link, :duration, :subtitle, :summary,
              :like_count, :image_title, :image_url, :duration_in_s]


  has_one :podcast, serializer: PanWeb.Api.PlainPodcastView, include: false
  has_many :chapters, serializer: PanWeb.Api.PlainChapterView, include: false
  has_many :recommendations, serializer: PanWeb.Api.PodcastRecommendationView, include: false
  has_many :enclosures, serializer: PanWeb.Api.PlainEnclosureView, include: false
  has_many :gigs, serializer: PanWeb.Api.PlainGigView, include: false
  has_many :contributors, serializer: PanWeb.Api.PlainPersonaView, include: false

  def orig_link(episode) do
    episode.link
  end

  def like_count(episode) do
    Episode.likes(episode.id)
  end

  def location(episode, conn) do
    api_episode_url(conn, :show, episode)
  end

  def duration_in_s(episode) do
    episode.duration |>
    DurationHelpers.duration_in_seconds()
  end
end


defmodule PanWeb.Api.PlainEpisodeView do
  use Pan.Web, :view
  use JaSerializer.PhoenixView

  def type(_, _), do: "episode"

  location :location
  attributes [:orig_link, :title, :publishing_date, :description, :deep_link, :duration, :subtitle,
              :summary, :image_title, :image_url, :duration_in_s]

  has_many :enclosures, serializer: PanWeb.Api.PlainEnclosureView, include: false

  def orig_link(episode) do
    episode.link
  end

  def location(episode, conn) do
    api_episode_url(conn, :show, episode)
  end

  def duration_in_s(episode) do
    episode.duration |>
    DurationHelpers.duration_in_seconds()
  end
end


defmodule DurationHelpers do
  def duration_in_seconds(duration) do
    duration = String.replace(duration, ~r/(.*?\:.*?\:.*?)(\:.*)/, "\\1")

    if String.match?(duration, ~r/^([0-9]+)(\:[0-9]{1,2})*$/) do
      if String.match?(duration, ~r/\:/) do
        fragments = String.split(duration, ":")
        fragments = if length(fragments) < 3, do: ["0" | fragments], else: fragments

        seconds(fragments, 0) + seconds(fragments, 1) + seconds(fragments, 2)
      else
        String.to_integer(duration)
      end
    else
      0
    end
  end

  defp seconds(fragments, fragment_index) do
    fragment_value =
      Enum.at(fragments, fragment_index)
      |> String.to_integer()

    fragment_value * :math.pow(60, Enum.count(fragments) - fragment_index - 1)
    |> round()
  end
end