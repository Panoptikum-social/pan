defmodule Pan.Chapter do
  use Pan.Web, :model
  alias Pan.Repo
  alias Pan.Like
  alias Pan.Chapter

  schema "chapters" do
    field :start, :string
    field :title, :string

    has_many :recommendations, Pan.Recommendation, on_delete: :delete_all
    has_many :likes, Pan.Like, on_delete: :delete_all
    belongs_to :episode, Pan.Episode

    timestamps()
  end


  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:start, :title])
    |> validate_required([:start, :title])
  end


  def like(chapter_id, user_id) do
    case Repo.get_by(Like, enjoyer_id: user_id,
                           chapter_id: chapter_id) do
      nil ->
        chapter = Repo.get(Chapter, chapter_id)
                  |> Repo.preload(:episode)
        %Like{enjoyer_id: user_id,
              chapter_id: chapter_id,
              episode_id: chapter.episode_id,
              podcast_id: chapter.episode.podcast_id}
        |> Repo.insert
      like ->
        Repo.delete!(like)
    end
  end


  def likes(id) do
    from(l in Like, where: l.chapter_id == ^id)
    |> Repo.aggregate(:count, :id)
    |> Integer.to_string
  end
end