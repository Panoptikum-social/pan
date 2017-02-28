defmodule Pan.Recommendation do
  use Pan.Web, :model
  alias Pan.Recommendation
  alias Pan.Repo

  @required_fields ~w(comment)
  @optional_fields ~w(podcast_id episode_id chapter_id user_id)

  schema "recommendations" do
    field :comment, :string
    belongs_to :user, Pan.User
    belongs_to :podcast, Pan.Podcast
    belongs_to :episode, Pan.Episode
    belongs_to :chapter, Pan.Chapter

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
  end


  def latest do
    from(Recommendation, order_by: [desc: :inserted_at],
                         limit: 10,
                         preload: [:user, :podcast, episode: :podcast,
                                   chapter: [episode: :podcast]])
    |> Repo.all()
  end
end
