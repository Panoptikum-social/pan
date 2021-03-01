defmodule PanWeb.Delegation do
  use PanWeb, :model

  schema "delegations" do
    belongs_to(:persona, PanWeb.Persona)
    belongs_to(:delegate, PanWeb.Persona)

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:persona_id, :delegate_id])
    |> validate_required([:persona_id, :delegate_id])
  end
end
