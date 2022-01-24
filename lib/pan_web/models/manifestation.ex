defmodule PanWeb.Manifestation do
  use PanWeb, :model
  alias PanWeb.Manifestation
  alias Pan.Repo

  schema "manifestations" do
    belongs_to(:persona, PanWeb.Persona)
    belongs_to(:user, PanWeb.User)

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:user_id, :persona_id])
    |> validate_required([:user_id, :persona_id])
  end

  def get_with_persona(user_id, persona_id) do
    from(m in Manifestation,
    where: m.user_id == ^user_id and m.persona_id == ^persona_id,
    preload: :persona
  )
  |> Repo.one()
  end
end
