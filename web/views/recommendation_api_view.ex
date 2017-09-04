defmodule Pan.RecommendationApiView do
  use Pan.Web, :view
  use JaSerializer.PhoenixView

  def type(_, _), do: "recommendation"

  location :recommendation_api_url
  attributes [:comment, :user_name]

  has_one :podcast, serializer: Pan.PlainPodcastApiView, include: true
  has_one :episode, serializer: Pan.PlainEpisodeApiView, include: true
  has_one :chapter, serializer: Pan.PlainChapterApiView, include: true

  def user_name(recommendation) do
    recommendation.user.name
  end

  def recommendation_api_url(recommendation, conn) do
    recommendation_api_url(conn, :show, recommendation)
  end
end


defmodule Pan.PodcastRecommendationApiView do
  use Pan.Web, :view
  use JaSerializer.PhoenixView

  def type(_, _), do: "recommendation"

  location :recommendation_api_url
  attributes [:comment, :user_name, :inserted_at]

  def user_name(recommendation) do
    recommendation.user.name
  end

  def recommendation_api_url(recommendation, conn) do
    recommendation_api_url(conn, :show, recommendation)
  end
end
