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
    |> validate_length(:name, min: 3, max: 100)
    |> validate_length(:email, min: 5, max: 100)
  end

  def registration_changeset(model, params) do
    model
    |> changeset(params)
    |> cast(params, ~w(password), [])
    |> validate_length(:password, min: 6, max: 100)
    |> put_pass_hash()
  end

  def put_pass_hash(changeset) do
    case changeset do
      %Ecto.Changeset{valid?: true, changes: %{password: pass}} ->
        put_change(changeset, :password_hash, Comeonin.Bcrypt.hashpwsalt(pass))
      _ ->
        changeset
    end
  end
end
