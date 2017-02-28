defmodule Pan.Engagement do
  use Pan.Web, :model

  @required_fields ~w(from until comment role)
  @optional_fields ~w()

  schema "engagements" do
    field :from, Ecto.Date
    field :until, Ecto.Date
    field :comment, :string
    field :role, :string
    belongs_to :persona, Pan.Persona
    belongs_to :podcast, Pan.Podcast

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