defmodule Pan.Manifestation do
  use Pan.Web, :model

  schema "manifestations" do
    belongs_to :persona, Pan.Persona
    belongs_to :user, Pan.User

    timestamps()
  end


  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:user_id, :persona_id])
    |> validate_required([:user_id, :persona_id])
  end
end
