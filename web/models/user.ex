defmodule Pan.User do
  use Pan.Web, :model
  alias Pan.Like
  alias Pan.Repo
  alias Pan.Follow

  @required_fields ~w(name username email)
  @optional_fields ~w(admin podcaster)


  schema "users" do
    field :name, :string
    field :username, :string
    field :password, :string, virtual: true
    field :password_confirmation, :string, virtual: true
    field :password_hash, :string
    field :email, :string
    field :admin, :boolean
    field :podcaster, :boolean
    timestamps

    has_many :podcasts_i_own, Pan.Podcast,
                              foreign_key: :owner_id
    many_to_many :podcasts_i_subscribed, Pan.Podcast,
                                         join_through: "subscriptions"
    has_many :contributor_identities, Pan.Contributor

    many_to_many :users_i_like, Pan.User,
                                join_through: "likes",
                                join_keys: [enjoyer_id: :id, user_id: :id]
    many_to_many :categories_i_like, Pan.Category,
                                     join_through: "likes",
                                     join_keys: [enjoyer_id: :id, category_id: :id]
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
    |> cast(params, ~w(password_confirmation), [])
    |> validate_confirmation(:password)
    |> validate_length(:password, min: 6, max: 100)
    |> put_pass_hash()
  end


  def password_update_changeset(model, params) do
    registration_changeset(model, params)
  end


  def request_login_changeset(model, params) do
    model
    |> changeset(params)
    |> cast(params, ~w(email), [])
    |> validate_length(:email, min: 5, max: 100)
  end


  def put_pass_hash(changeset) do
    case changeset do
      %Ecto.Changeset{valid?: true, changes: %{password: pass}} ->
        put_change(changeset, :password_hash, Comeonin.Bcrypt.hashpwsalt(pass))
      _ ->
        changeset
    end
  end


  def like(user_id, current_user_id) do
    case Repo.get_by(Like, enjoyer_id: current_user_id,
                           user_id: user_id) do
      nil ->
        %Like{enjoyer_id: current_user_id, user_id: user_id}
        |> Repo.insert
      like ->
        Repo.delete!(like)
    end
  end


  def follow(user_id, current_user_id) do
    case Repo.get_by(Follow, follower_id: current_user_id,
                             user_id: user_id) do
      nil ->
        %Follow{follower_id: current_user_id, user_id: user_id}
        |> Repo.insert
      like ->
        Repo.delete!(like)
    end
  end


  def follower_mailboxes(user_id) do
    Repo.all(from l in Follow, where: l.user_id == ^user_id,
                               select: [:follower_id])
    |> Enum.map(fn(user) ->  "mailboxes:" <> Integer.to_string(user.follower_id) end)
  end


  def likes(id) do
    from(l in Like, where: l.user_id == ^id)
    |> Repo.aggregate(:count, :id)
    |> Integer.to_string
  end


  def follows(id) do
    from(f in Follow, where: f.user_id == ^id)
    |> Repo.aggregate(:count, :id)
    |> Integer.to_string
  end


  def popularity(id) do
    followers = from(f in Follow, where: f.user_id == ^id)
    |> Repo.aggregate(:count, :id)

    likes = from(l in Like, where: l.user_id == ^id)
    |> Repo.aggregate(:count, :id)

    Integer.to_string(followers + likes)
  end


  def subscribed_user_ids(user_id) do
    case Repo.all(from f in Follow, where: f.follower_id == ^user_id and
                                           not is_nil(f.user_id),
                                    select: f.user_id) do
      [] ->
        ["0"]
      array ->
        Enum.map(array, fn(id) ->  Integer.to_string(id) end)
    end
  end


  def subscribed_category_ids(user_id) do
    case Repo.all(from f in Follow, where: f.follower_id == ^user_id and
                                           not is_nil(f.category_id),
                                    select: f.category_id) do
      [] ->
        ["0"]
      array ->
        Enum.map(array, fn(id) ->  Integer.to_string(id) end)
    end
  end


  def subscribed_podcast_ids(user_id) do
    case Repo.all(from f in Follow, where: f.follower_id == ^user_id and
                                           not is_nil(f.podcast_id),
                                    select: f.podcast_id) do
      [] ->
        ["0"]
      array ->
        Enum.map(array, fn(id) ->  Integer.to_string(id) end)
    end
  end
end