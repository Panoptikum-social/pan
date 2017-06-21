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
    |> cast(params, [:from, :until, :comment, :role, :persona_id, :podcast_id])
    |> validate_required([:comment, :role, :persona_id, :podcast_id])
  end
end
