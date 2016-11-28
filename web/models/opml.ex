defmodule Pan.OPML do
  use Pan.Web, :model

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
    |> cast(params, [:content_type, :filename, :path])
    |> validate_required([:content_type, :filename, :path])
  end
end
