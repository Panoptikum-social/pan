defmodule Pan.Like do
  use Pan.Web, :model
  alias Pan.Like
  alias Pan.Repo

  schema "likes" do
    belongs_to :enjoyer, Pan.User
    belongs_to :podcast, Pan.Podcast
    belongs_to :episode, Pan.Episode
    belongs_to :chapter, Pan.Chapter
    belongs_to :user, Pan.User
    belongs_to :persona, Pan.Persona
    belongs_to :category, Pan.Category

    timestamps()
  end


  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:user_id, :persona_id, :enjoyer_id, :podcast_id, :episode_id,
                     :chapter_id, :category_id])
    |> validate_required([:enjoyer_id])
  end


  def find_episode_like(user_id, episode_id) do
    from(l in Like, where: is_nil(l.chapter_id) and
                           l.enjoyer_id == ^user_id and
                           l.episode_id == ^episode_id)
    |> Repo.one
  end


  def find_podcast_like(user_id, podcast_id) do
    from(l in Like, where: is_nil(l.chapter_id) and
                           is_nil(l.episode_id) and
                           l.enjoyer_id == ^user_id and
                           l.podcast_id == ^podcast_id)
    |> Repo.one
  end
end