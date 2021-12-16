defmodule PanWeb.Engagement do
  use PanWeb, :model
  alias Pan.Repo
  alias PanWeb.Engagement

  schema "engagements" do
    field(:from, :date)
    field(:until, :date)
    field(:comment, :string)
    field(:role, :string)
    belongs_to(:persona, PanWeb.Persona)
    belongs_to(:podcast, PanWeb.Podcast)

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:from, :until, :comment, :role, :persona_id, :podcast_id])
    |> validate_required([:role])
  end

  def get_by_persona_ids(persona_ids) do
    from(e in Engagement,
      where: e.persona_id in ^persona_ids,
      preload: :podcast
    )
    |> Repo.all()
  end
end
