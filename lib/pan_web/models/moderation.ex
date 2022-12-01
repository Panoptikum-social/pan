defmodule PanWeb.Moderation do
  use PanWeb, :model

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
end
