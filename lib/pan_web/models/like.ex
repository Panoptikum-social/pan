defmodule PanWeb.Like do
  use PanWeb, :model
  alias Pan.Repo
  alias PanWeb.Like

  schema "likes" do
    belongs_to(:enjoyer, PanWeb.User)
    belongs_to(:podcast, PanWeb.Podcast)
    belongs_to(:episode, PanWeb.Episode)
    belongs_to(:chapter, PanWeb.Chapter)
    belongs_to(:user, PanWeb.User)
    belongs_to(:persona, PanWeb.Persona)
    belongs_to(:category, PanWeb.Category)

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :user_id,
      :persona_id,
      :enjoyer_id,
      :podcast_id,
      :episode_id,
      :chapter_id,
      :category_id
    ])
    |> validate_required([:enjoyer_id])
  end

  def find_episode_like(user_id, episode_id) do
    from(l in Like,
      where:
        l.enjoyer_id == ^user_id and
          l.episode_id == ^episode_id
    )
    |> Repo.one()
  end

  def find_podcast_like(user_id, podcast_id) do
    from(l in Like,
      where:
        l.enjoyer_id == ^user_id and
          l.podcast_id == ^podcast_id
    )
    |> Repo.one()
  end

  def find_persona_like(user_id, persona_id) do
    from(l in Like,
      where:
        l.enjoyer_id == ^user_id and
          l.persona_id == ^persona_id
    )
    |> Repo.one()
  end

  def find_category_like(user_id, category_id) do
    from(l in Like,
      where:
        l.enjoyer_id == ^user_id and
          l.category_id == ^category_id
    )
    |> Repo.one()
  end

  def find_chapter_like(user_id, chapter_id) do
    from(l in Like,
      where:
        l.enjoyer_id == ^user_id and
          l.chapter_id == ^chapter_id
    )
    |> Repo.one()
  end

  def find_user_like(enjoyer_id, liked_user_id) do
    from(l in Like,
      where:
        l.enjoyer_id == ^enjoyer_id and
          l.user_id == ^liked_user_id
    )
    |> Repo.one()
  end

  def get_podcast_related(user_id) do
    from(l in Like,
      where: l.enjoyer_id == ^user_id and not is_nil(l.podcast_id),
      order_by: [desc: :inserted_at]
    )
    |> Repo.all()
    |> Repo.preload([:podcast, [episode: :podcast], [chapter: [episode: :podcast]]])
  end
end
