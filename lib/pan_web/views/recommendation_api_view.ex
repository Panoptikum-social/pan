defmodule PanWeb.RecommendationApiView do
  use Pan.Web, :view
  use JaSerializer.PhoenixView

  def type(_, _), do: "recommendation"

  location :recommendation_api_url
  attributes [:comment, :user_name]

  has_one :podcast, serializer: PanWeb.PlainPodcastApiView, include: false
  has_one :episode, serializer: PanWeb.PlainEpisodeApiView, include: false
  has_one :chapter, serializer: PanWeb.PlainChapterApiView, include: false
  has_one :category, serializer: PanWeb.PlainCategoryApiView, include: false

  def user_name(recommendation) do
    recommendation.user.name
  end

  def recommendation_api_url(recommendation, conn) do
    recommendation_api_url(conn, :show, recommendation)
  end
end


defmodule PanWeb.PodcastRecommendationApiView do
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
