defmodule Pan.Delegation do
  use Pan.Web, :model

  schema "delegations" do
    belongs_to :persona, Pan.Persona
    belongs_to :delegate, Pan.Persona

    timestamps()
  end


  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:persona_id, :delegate_id])
    |> validate_required([:persona_id, :delegate_id])
  end
end
