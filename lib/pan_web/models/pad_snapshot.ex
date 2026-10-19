defmodule PanWeb.PadSnapshot do
  use PanWeb, :model

  # A saved version of a pad's markdown: automatic (no user, no note) or from
  # "Save version" (user and optional note). All snapshots are kept.
  schema "pad_snapshots" do
    field(:markdown, Ecto.EctoText)
    field(:note, :string)

    belongs_to(:pad, PanWeb.Pad)
    belongs_to(:user, PanWeb.User)

    timestamps(updated_at: false)
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:markdown, :note])
    |> validate_required([:markdown])
    |> validate_length(:note, max: 255)
  end
end
