defmodule Pan.Recommendation do
  use Pan.Web, :model
  alias Pan.Recommendation
  alias Pan.Repo

  schema "recommendations" do
    field :comment, :string
    belongs_to :user, Pan.User
    belongs_to :podcast, Pan.Podcast
    belongs_to :episode, Pan.Episode
    belongs_to :chapter, Pan.Chapter

    timestamps()
  end


  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:comment])
    |> validate_required([:comment, :podcast_id, :episode_id, :chapter_id, :user_id])
  end


  def latest do
    from(Recommendation, order_by: [desc: :inserted_at],
                         limit: 10,
                         preload: [:user, :podcast, episode: :podcast,
                                   chapter: [episode: :podcast]])
    |> Repo.all()
  end
end
