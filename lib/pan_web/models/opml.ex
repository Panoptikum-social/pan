defmodule PanWeb.Opml do
  use Pan.Web, :model

  schema "opmls" do
    field :content_type, :string
    field :filename, :string
    field :path, :string
    belongs_to :user, PanWeb.User

    timestamps()
  end


  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:content_type, :filename, :path, :user_id, :inserted_at])
    |> validate_required([:content_type, :filename, :path])
  end
end
