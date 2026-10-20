defmodule PanWeb.PadSnapshot do
  use PanWeb, :model
  alias Pan.Repo
  alias PanWeb.PadSnapshot

  # A saved version of a pad's markdown: automatic (no user, no note) or from
  # "Save version" (user and optional note). All snapshots are kept.
  schema "pad_snapshots" do
    field(:markdown, Ecto.EctoText)
    field(:note, :string)

    belongs_to(:pad, PanWeb.Pad)
    belongs_to(:user, PanWeb.User)

    timestamps(updated_at: false)
  end

  # the markdown is set on the struct: casting would turn an empty pad's ""
  # into nil
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:note])
    |> update_change(:note, &String.trim/1)
    |> validate_length(:note, max: 255)
    # a pad deleted while open simply gets no more snapshots
    |> foreign_key_constraint(:pad_id)
  end

  @doc "The text of the pad's latest snapshot, the empty pad's if there is none."
  def latest_markdown(pad_id) do
    from(s in PadSnapshot,
      where: s.pad_id == ^pad_id,
      order_by: [desc: s.inserted_at, desc: s.id],
      limit: 1,
      select: s.markdown
    )
    |> Repo.one() || ""
  end

  @doc "All snapshots of a pad, newest first, with the name of who saved them."
  def list_for(pad_id) do
    from(s in PadSnapshot,
      where: s.pad_id == ^pad_id,
      left_join: u in assoc(s, :user),
      order_by: [desc: s.inserted_at, desc: s.id],
      select: %{
        id: s.id,
        note: s.note,
        user_id: s.user_id,
        user_name: u.name,
        inserted_at: s.inserted_at
      }
    )
    |> Repo.all()
  end
end
