defmodule Pan.Opml do
  use Pan.Web, :model

  @required_fields ~w(content_type filename path)
  @optional_fields ~w(user_id inserted_at)

  schema "opmls" do
    field :content_type, :string
    field :filename, :string
    field :path, :string
    belongs_to :user, Pan.User

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
