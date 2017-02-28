defmodule Pan.Gig do
  use Pan.Web, :model

  @required_fields ~w(publishing_date role)
  @optional_fields ~w(from_in_s until_in_s comment)

  schema "gigs" do
    field :from_in_s, :integer
    field :until_in_s, :integer
    field :comment, :string
    field :publishing_date, Ecto.DateTime
    field :role, :string
    belongs_to :persona, Pan.Persona
    belongs_to :episode, Pan.Episode

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
