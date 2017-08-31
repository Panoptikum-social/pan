defmodule Pan.EpisodeApiView do
  use Pan.Web, :view
  use JaSerializer.PhoenixView

  def type(_, _), do: "episode"

  location "https://panoptikum.io/jsonapi/episodes/:id"
  attributes [:orig_link, :title, :publishing_date, :guid, :description, :shownotes,
              :payment_link_title, :payment_link_url, :deep_link, :duration, :subtitle, :summary]


  has_many :episode, serializer: Pan.ReducedEpisodeApiView, include: false

  def orig_link(episode) do
    episode.link
  end
end


defmodule Pan.ReducedEpisodeApiView do
  use Pan.Web, :view
  use JaSerializer.PhoenixView

  def type(_, _), do: "episode"

  location "https://panoptikum.io/jsonapi/episodes/:id"
  attributes [:orig_link, :title, :publishing_date, :description, :deep_link, :duration, :subtitle,
              :summary]

  def orig_link(episode) do
    episode.link
  end
end
