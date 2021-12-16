defmodule PanWeb.Delegation do
  use PanWeb, :model
  alias Pan.Repo
  alias PanWeb.Delegation

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

  def get_by_delegate_id(delegate_id) do
    from(d in Delegation,
      where: d.delegate_id == ^delegate_id,
      select: d.persona_id
    )
    |> Repo.all()
  end
end
