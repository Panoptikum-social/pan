defmodule Pan.RecommendationApiView do
  use Pan.Web, :view
  use JaSerializer.PhoenixView

  def type(_, _), do: "recommendation"

  location "https://panoptikum.io/jsonapi/recommendations/:id"
  attributes [:comment, :user_name]

#  has_one :user, serializer: Pan.PlainUserApiView, include: true
  has_one :podcast, serializer: Pan.ReducedPodcastApiView, include: true
#  has_one :episode, serializer: Pan.PlainEpisodeApiView, include: true
#  has_one :chapter, serializer: Pan.ChapterApiView, include: true

end


defmodule Pan.PodcastRecommendationApiView do
  use Pan.Web, :view
  use JaSerializer.PhoenixView

  def type(_, _), do: "recommendation"

  location "https://panoptikum.io/jsonapi/recommendations/:id"
  attributes [:comment, :user_name, :inserted_at]

  def user_name(recommendation) do
    recommendation.user.name
  end
end
