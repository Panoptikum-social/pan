defmodule Pan.User do
  use Pan.Web, :model

  schema "users" do
    field :name, :string
    field :username, :string
    field :password, :string, virtual: true
    field :password_hash, :string
    field :email, :string

    timestamps
  end

  def changeset(model, params \\ :empty) do
    model
    |> cast(params, ~w(name username email), [])
    |> validate_length(:username, min: 3, max: 30)
  end
end
