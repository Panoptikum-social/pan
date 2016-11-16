defmodule Pan.User do
  use Pan.Web, :model

  @required_fields ~w(name username email)
  @optional_fields ~w(admin podcaster)


  schema "users" do
    field :name, :string
    field :username, :string
    field :password, :string, virtual: true
    field :password_hash, :string
    field :email, :string
    field :admin, :boolean
    field :podcaster, :boolean
    timestamps

    has_many :owned_podcasts, Pan.Podcast, foreign_key: "owner_id"
    has_many :contributor_identities, Pan.Contributor

    many_to_many :subscribed_podcasts, Pan.Podcast, join_through: "subscriptions"

#    many_to_many :podcasts_user_follows, Pan.Podcast,
#                 join_through: "followes", join_keys: [follower_id: :id, podcast_id: :id]
#    many_to_many :followers, Pan.User,
#                 join_through: "follows", join_keys: [user_id: :id, follower_id: :id]
#    many_to_many :users_user_follows, Pan.User,
#                 join_through: "follows", join_keys: [follower_id: :id, user_id: :id]
  end

  def changeset(model, params \\ %{}) do
    model
    |> cast(params, @required_fields, @optional_fields)
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
