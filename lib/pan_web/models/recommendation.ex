defmodule PanWeb.Recommendation do
  use PanWeb, :model
  alias Pan.Repo
  alias PanWeb.Recommendation

  schema "recommendations" do
    field(:comment, :string)
    belongs_to(:user, PanWeb.User)
    belongs_to(:podcast, PanWeb.Podcast)
    belongs_to(:episode, PanWeb.Episode)
    belongs_to(:chapter, PanWeb.Chapter)

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:comment, :podcast_id, :episode_id, :chapter_id, :user_id])
    |> validate_required([:comment])
  end

  def latest do
    from(r in Recommendation,
      order_by: [fragment("? DESC NULLS LAST", r.inserted_at)],
      preload: [:user, :podcast, episode: :podcast, chapter: [episode: :podcast]],
      select: [:comment, :inserted_at, :user_id, :podcast_id, :episode_id, :chapter_id,
               user: [:id, :name],
               podcast: [:id, :title],
               episode: [:id, :title, :podcast_id, podcast: [:id, :title]],
               chapter: [:title, :episode_id, episode: [:id, :title, :podcast_id, podcast: [:id, :title]]]
              ],
      limit: 10
    )
    |> Repo.all()
  end
end
