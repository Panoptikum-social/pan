defmodule PanWeb.Api.ChapterView do
  use PanWeb, :view
  use JaSerializer.PhoenixView
  alias PanWeb.Chapter

  def type(_, _), do: "chapter"

  location(:location)
  attributes([:start, :title, :like_count])

  has_one(:episode, serializer: PanWeb.Api.PlainEpisodeView, include: false)
  has_many(:recommendations, serializer: PanWeb.Api.PodcastRecommendationView, include: false)

  def like_count(chapter) do
    Chapter.likes(chapter.id)
  end

  def location(chapter, conn) do
    api_chapter_url(conn, :show, chapter)
  end
end

defmodule PanWeb.Api.PlainChapterView do
  use PanWeb, :view
  use JaSerializer.PhoenixView

  def type(_, _), do: "chapter"

  location(:location)
  attributes([:start, :title])

  def location(chapter, conn) do
    api_chapter_url(conn, :show, chapter)
  end
end
