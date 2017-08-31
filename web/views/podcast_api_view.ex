defmodule Pan.PodcastApiView do
  use Pan.Web, :view
  use JaSerializer.PhoenixView
  alias Pan.Podcast

  def type(_, _), do: "podcast"

  location "https://panoptikum.io/jsonapi/podcasts/:id"
  attributes [:title, :website, :description, :summary, :image_title, :image_url, :last_build_date,
              :payment_link_title, :payment_link_url, :explicit, :update_paused, :blocked,
              :update_paused, :update_intervall, :next_update, :retired, :unique_identifier,
              :follower_count, :like_count, :subscription_count]

  has_many :episodes, serializer: Pan.ReducedEpisodeApiView, include: false

  def follower_count(podcast) do
    Podcast.follows(podcast.id)
  end

  def like_count(podcast) do
    Podcast.likes(podcast.id)
  end

  def subscription_count(podcast) do
    Podcast.subscriptions(podcast.id)
  end
end


defmodule Pan.ReducedPodcastApiView do
  use Pan.Web, :view
  use JaSerializer.PhoenixView

  def type(_, _), do: "podcast"

  location "https://panoptikum.io/jsonapi/podcasts/:id"
  attributes [:title, :website, :description, :image_title, :image_url]
end
