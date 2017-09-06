defmodule PanWeb.Manifestation do
  use Pan.Web, :model

  schema "manifestations" do
    belongs_to :persona, PanWeb.Persona
    belongs_to :user, PanWeb.User

    timestamps()
  end


  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:user_id, :persona_id])
    |> validate_required([:user_id, :persona_id])
  end
end
