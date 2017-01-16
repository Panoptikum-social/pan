defmodule Pan.Persona do
  use Pan.Web, :model

  schema "personas" do
    field :pid, :string
    field :name, :string
    field :uri, :string
    field :email, :string
    field :description, :string
    field :image_url, :string
    field :image_title, :string

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:pid, :name, :uri, :email, :description, :image_url, :image_title])
    |> validate_required([:pid, :name, :uri, :email, :description, :image_url, :image_title])
  end
end
