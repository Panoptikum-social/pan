defmodule PanWeb.Invoice do
  use PanWeb, :model

  schema "invoices" do
    field(:filename, :string)
    field(:content_type, :string)
    field(:path, :string)
    belongs_to(:user, PanWeb.User)

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:filename, :content_type, :path, :user_id])
    |> validate_required([:filename, :content_type, :path, :user_id])
  end
end
