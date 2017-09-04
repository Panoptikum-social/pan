defmodule Pan.ChapterApiView do
  use Pan.Web, :view
  use JaSerializer.PhoenixView
  alias Pan.Chapter

  def type(_, _), do: "chapter"

  location :chapter_api_url
  attributes [:start, :title, :like_count]

  has_one :episode, serializer: Pan.PlainEpisodeApiView, include: false
  has_many :recommendations, serializer: Pan.PodcastRecommendationApiView, include: false

  def like_count(chapter) do
    Chapter.likes(chapter.id)
  end

  def chapter_api_url(chapter, conn) do
    chapter_api_url(conn, :show, chapter)
  end
end


defmodule Pan.PlainChapterApiView do
  use Pan.Web, :view
  use JaSerializer.PhoenixView

  def type(_, _), do: "chapter"

  location :chapter_api_url
  attributes [:start, :title]

  def chapter_api_url(chapter, conn) do
    chapter_api_url(conn, :show, chapter)
  end
end
