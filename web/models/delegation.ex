defmodule Pan.Delegation do
  use Pan.Web, :model

  @required_fields ~w(persona_id delegate_id)

  schema "delegations" do
    belongs_to :persona, Pan.Persona
    belongs_to :delegate, Pan.Persona

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @required_fields)
    |> validate_required([])
  end
end
