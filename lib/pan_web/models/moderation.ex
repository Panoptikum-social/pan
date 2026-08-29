defmodule PanWeb.Moderation do
  use PanWeb, :model
  alias PanWeb.Moderation
  alias Pan.Repo

  @primary_key false

  schema "moderations" do
    # category_id is gone from this schema entirely — the DB column still
    # exists (kept per backlog.md, still holds real data on the rows that
    # predate Community) but is no longer written or queried through Ecto.
    # community_id is the real identity now: a Community is unique per
    # category_id, so moderation.community.category was always reachable and
    # is the only path to "which category" going forward.
    belongs_to(:user, PanWeb.User, primary_key: true)
    belongs_to(:community, PanWeb.Community, primary_key: true)
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:user_id, :community_id])
    |> validate_required([:user_id, :community_id])
  end

  def get_by_catagory_id_and_user_id(category_id, user_id) do
    from(m in Moderation,
      join: c in assoc(m, :community),
      where: c.category_id == ^category_id and m.user_id == ^user_id,
      preload: [community: :category]
    )
    |> Repo.one()
  end
end
