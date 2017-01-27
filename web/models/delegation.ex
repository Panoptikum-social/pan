defmodule Pan.Delegation do
  use Pan.Web, :model

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
    |> cast(params, [])
    |> validate_required([])
  end
end
