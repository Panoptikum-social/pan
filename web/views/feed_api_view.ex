defmodule Pan.FeedApiView do
  use Pan.Web, :view
  use JaSerializer.PhoenixView

  def type(_, _), do: "feed"

  location "https://panoptikum.io/jsonapi/feeds/:id"
  attributes [:self_link_title, :self_link_url, :next_page_url, :prev_page_url, :first_page_url,
              :last_page_url, :hub_link_url, :feed_generator]

  has_one :podcast,    serializer: Pan.PlainPodcastApiView, include: true
  has_many :alternate_feeds, serializer: Pan.PlainAlternateFeedApiView, include: true
end


defmodule Pan.PlainFeedApiView do
  use Pan.Web, :view
  use JaSerializer.PhoenixView

  def type(_, _), do: "feed"

  location "https://panoptikum.io/jsonapi/feeds/:id"
  attributes [:self_link_title, :self_link_url, :next_page_url, :prev_page_url, :first_page_url,
              :last_page_url, :hub_link_url, :feed_generator]

end
