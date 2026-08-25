defmodule PanWeb.UserLanguage do
  use PanWeb, :model

  @primary_key false

  schema "users_languages" do
    belongs_to(:user, PanWeb.User, primary_key: true)
    belongs_to(:language, PanWeb.Language, primary_key: true)
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:user_id, :language_id])
    |> validate_required([:user_id, :language_id])
  end
end
