defmodule PanWeb.Moderation do
  use PanWeb, :model
  alias PanWeb.Moderation
  alias Pan.Repo

  @primary_key false

  schema "moderations" do
    belongs_to(:category, PanWeb.Category, primary_key: true)
    belongs_to(:user, PanWeb.User, primary_key: true)
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:category_id, :user_id])
    |> validate_required([:category_id, :user_id])
  end

  def get_by_catagory_id_and_user_id(category_id, user_id) do
    from(m in Moderation, where: m.category_id == ^category_id and m.user_id == ^user_id)
    |> Repo.one
    |> Repo.preload(:category)
  end
end
