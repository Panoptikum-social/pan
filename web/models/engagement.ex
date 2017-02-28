defmodule Pan.Engagement do
  use Pan.Web, :model

  schema "engagements" do
    field :from, Ecto.Date
    field :until, Ecto.Date
    field :comment, :string
    field :role, :string
    belongs_to :persona, Pan.Persona
    belongs_to :podcast, Pan.Podcast

    timestamps()
  end


  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:from, :suntil, :comment, :role])
    |> validate_required([:from, :suntil, :comment, :role])
  end
end