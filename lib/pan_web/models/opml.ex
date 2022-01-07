defmodule PanWeb.Opml do
  use PanWeb, :model
  alias PanWeb.Opml
  alias Pan.Repo

  schema "opmls" do
    field(:content_type, :string)
    field(:filename, :string)
    field(:path, :string)
    belongs_to(:user, PanWeb.User)

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:content_type, :filename, :path, :user_id, :inserted_at])
    |> validate_required([:content_type, :filename, :path])
  end

  def all_with_user(sort_by, sort_order) do
    from(o in Opml,
      order_by: [{^sort_order, ^sort_by}],
      preload: :user
    )
    |> Repo.all()
  end
end
