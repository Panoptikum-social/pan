defmodule Pan.Like do
  use Pan.Web, :model
  alias Pan.Like
  alias Pan.Repo


  schema "likes" do
    field :comment, :string
    belongs_to :enjoyer, Pan.User
    belongs_to :podcast, Pan.Podcast
    belongs_to :episode, Pan.Episode
    belongs_to :chapter, Pan.Chapter
    belongs_to :user, Pan.User
    belongs_to :category, Pan.Category
    belongs_to :recommend_to, Pan.User

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [])
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