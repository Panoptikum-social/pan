defmodule Pan.Like do
  use Pan.Web, :model
  alias Pan.Like
  alias Pan.Repo

  @required_fields ~w()
  @optional_fields ~w(user_id persona_id)

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

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
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