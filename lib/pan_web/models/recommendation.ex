defmodule PanWeb.Recommendation do
  use Pan.Web, :model
  alias PanWeb.Recommendation
  alias Pan.Repo

  schema "recommendations" do
    field :comment, :string
    belongs_to :user, PanWeb.User
    belongs_to :podcast, PanWeb.Podcast
    belongs_to :episode, PanWeb.Episode
    belongs_to :chapter, PanWeb.Chapter

    timestamps()
  end


  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:comment, :podcast_id, :episode_id, :chapter_id, :user_id])
    |> validate_required([:comment])
  end


  def latest do
    from(Recommendation, order_by: [desc: :inserted_at],
                         limit: 10,
                         preload: [:user, :podcast, episode: :podcast,
                                   chapter: [episode: :podcast]])
    |> Repo.all()
  end
end
