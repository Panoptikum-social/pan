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
      left_join: u in assoc(r, :user),
      left_join: p in assoc(r, :podcast),
      left_join: e in assoc(r, :episode),
      left_join: pe in assoc(e, :podcast),
      left_join: c in assoc(r, :chapter),
      left_join: ec in assoc(c, :episode),
      left_join: pc in assoc(ec, :podcast),
      preload: [
        user: u,
        podcast: p,
        episode: {e, podcast: pe},
        chapter: {c, episode: {ec, podcast: pc}}
      ],
      select: [
        :id,
        :comment,
        :inserted_at,
        user: [:id, :name],
        podcast: [:id, :title],
        episode: [:id, :title, :podcast_id, podcast: [:id, :title]],
        chapter: [
          :id,
          :title,
          :episode_id,
          episode: [:id, :title, :podcast_id, podcast: [:id, :title]]
        ]
      ],
      limit: 1
    )
    |> Repo.one()
  end

  def get_by_podcast_id(podcast_id, page, per_page) do
    from(r in Recommendation,
      where: r.podcast_id == ^podcast_id,
      order_by: [fragment("? DESC NULLS LAST", r.inserted_at)],
      preload: [:user],
      limit: ^per_page,
      offset: (^page - 1) * ^per_page
    )
    |> Repo.all()
  end

  def get_by_episode_id(episode_id, page, per_page) do
    from(r in Recommendation,
      where: r.episode_id == ^episode_id,
      order_by: [fragment("? DESC NULLS LAST", r.inserted_at)],
      preload: [:user],
      limit: ^per_page,
      offset: (^page - 1) * ^per_page
    )
    |> Repo.all()
  end

  def get_by_chapter_id(chapter_id, page, per_page) do
    from(r in Recommendation,
      where: r.chapter_id == ^chapter_id,
      order_by: [fragment("? DESC NULLS LAST", r.inserted_at)],
      preload: [:user],
      limit: ^per_page,
      offset: (^page - 1) * ^per_page
    )
    |> Repo.all()
  end

  def count_by_podcast_id(podcast_id) do
    from(r in Recommendation, where: r.podcast_id == ^podcast_id)
    |> Repo.aggregate(:count)
  end

  def latest(page, per_page) do
    from(p in Recommendation,
      order_by: [desc: :inserted_at],
      preload: [:user, :podcast, episode: :podcast, chapter: [episode: :podcast]],
      limit: ^per_page,
      offset: (^page - 1) * ^per_page
    )
    |> Repo.all()
  end
end
