defmodule Pan.ChapterApiView do
  use Pan.Web, :view
  use JaSerializer.PhoenixView
  alias Pan.Chapter

  def type(_, _), do: "chapter"

  location "https://panoptikum.io/jsonapi/chapters/:id"
  attributes [:start, :title, :like_count]

  has_one :episode, serializer: Pan.PlainEpisodeApiView, include: false
  has_many :recommendations, serializer: Pan.PodcastRecommendationApiView, include: false

  def like_count(chapter) do
    Chapter.likes(chapter.id)
  end
end


defmodule Pan.PlainChapterApiView do
  use Pan.Web, :view
  use JaSerializer.PhoenixView

  def type(_, _), do: "chapter"

  location "https://panoptikum.io/jsonapi/chapters/:id"
  attributes [:start, :title]
end
