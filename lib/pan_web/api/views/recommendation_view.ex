defmodule PanWeb.Api.RecommendationView do
  use Pan.Web, :view
  use JaSerializer.PhoenixView

  def type(_, _), do: "recommendation"

  location(:location)
  attributes([:comment, :user_name])

  has_one(:podcast, serializer: PanWeb.Api.PlainPodcastView, include: false)
  has_one(:episode, serializer: PanWeb.Api.PlainEpisodeView, include: false)
  has_one(:chapter, serializer: PanWeb.Api.PlainChapterView, include: false)
  has_one(:category, serializer: PanWeb.Api.PlainCategoryView, include: false)
  has_one(:user, serializer: PanWeb.Api.PlainUserView, include: false)

  def location(recommendation, conn) do
    api_recommendation_url(conn, :show, recommendation)
  end
end

defmodule PanWeb.Api.PlainRecommendationView do
  use Pan.Web, :view
  use JaSerializer.PhoenixView

  def type(_, _), do: "recommendation"

  location(:location)
  attributes([:comment, :user_id, :podcast_id, :episode_id, :chapter_id, :category_id])

  def location(recommendation, conn) do
    api_recommendation_url(conn, :show, recommendation)
  end
end

defmodule PanWeb.Api.PodcastRecommendationView do
  use Pan.Web, :view
  use JaSerializer.PhoenixView

  def type(_, _), do: "recommendation"

  location(:location)
  attributes([:comment, :user_name, :inserted_at])

  def user_name(recommendation) do
    recommendation.user.name
  end

  def location(recommendation, conn) do
    api_recommendation_url(conn, :show, recommendation)
  end
end
