defmodule Pan.Gig do
  use Pan.Web, :model

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
    |> cast(params, [:from_in_s, :until_in_s, :comment, :publishing_date, :role])
    |> validate_required([:from_in_s, :until_in_s, :comment, :publishing_date, :role])
  end
end
