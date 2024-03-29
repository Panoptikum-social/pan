defmodule PanWeb.Follow do
  use PanWeb, :model
  alias Pan.Repo
  alias PanWeb.Follow

  schema "follows" do
    belongs_to(:follower, PanWeb.User)
    belongs_to(:podcast, PanWeb.Podcast)
    belongs_to(:user, PanWeb.User)
    belongs_to(:persona, PanWeb.Persona)
    belongs_to(:category, PanWeb.Category)

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:user_id, :persona_id, :follower_id, :podcast_id, :category_id])
    |> validate_required([:follower_id])
  end

  def find_podcast_follow(user_id, podcast_id) do
    Repo.get_by(Follow,
      follower_id: user_id,
      podcast_id: podcast_id
    )
  end

  def find_persona_follow(user_id, persona_id) do
    Repo.get_by(Follow,
      follower_id: user_id,
      persona_id: persona_id
    )
  end

  def find_category_follow(user_id, category_id) do
    Repo.get_by(Follow,
      follower_id: user_id,
      category_id: category_id
    )
  end

  def find_user_follow(follower_id, user_id) do
    Repo.get_by(Follow,
      follower_id: follower_id,
      user_id: user_id
    )
  end
end
