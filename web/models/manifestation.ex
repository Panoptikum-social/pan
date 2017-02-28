defmodule Pan.Manifestation do
  use Pan.Web, :model

  @required_fields ~w()
  @optional_fields ~w(user_id persona_id)

  schema "manifestations" do
    belongs_to :persona, Pan.Persona
    belongs_to :user, Pan.User

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
  end
end
