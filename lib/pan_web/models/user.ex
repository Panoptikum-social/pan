defmodule PanWeb.User do
  use Pan.Web, :model
  alias Pan.Repo
  alias PanWeb.{Category, Chapter, Episode, Follow, Invoice, Like, Manifestation, Message,
                Opml, Persona, Podcast, Recommendation, User, Subscription}

  schema "users" do
    field :name, :string
    field :username, :string
    field :password, :string, virtual: true
    field :password_confirmation, :string, virtual: true
    field :password_hash, :string
    field :email, :string
    field :admin, :boolean
    field :podcaster, :boolean
    field :email_confirmed, :boolean
    field :share_subscriptions, :boolean, default: false
    field :share_follows, :boolean, default: false
    field :pro_until, :naive_datetime
    field :billing_address, :string
    field :payment_reference, :string
    field :paper_bill, :boolean
    field :elastic, :boolean
    field :bot_check, :integer, virtual: true
    timestamps()

    has_many :manifestations, Manifestation, on_delete: :delete_all
    has_many :invoices, Invoice, on_delete: :nilify_all
    has_many :user_personas, Persona, foreign_key: :user_id
    has_many :recommendations, Recommendation, on_delete: :delete_all
    has_many :messages_created, Message, foreign_key: :creator_id, on_delete: :delete_all
    has_many :opmls, Opml, on_delete: :delete_all

    many_to_many :personas, Persona,
                            join_through: "manifestations"

    many_to_many :podcasts_i_subscribed, Podcast,
                                         join_through: "subscriptions"

    many_to_many :users_i_like, User,
                                join_through: "likes",
                                join_keys: [enjoyer_id: :id, user_id: :id]
    many_to_many :users_i_follow, User,
                                  join_through: "follows",
                                  join_keys: [follower_id: :id, user_id: :id]
    many_to_many :personas_i_like, Persona,
                                   join_through: "likes",
                                   join_keys: [enjoyer_id: :id, persona_id: :id]
    many_to_many :personas_i_follow, Persona,
                                     join_through: "follows",
                                     join_keys: [follower_id: :id, persona_id: :id]
    many_to_many :podcasts_i_follow, Podcast,
                                     join_through: "follows",
                                     join_keys: [follower_id: :id, podcast_id: :id]
    many_to_many :podcasts_i_like, Podcast,
                                   join_through: "likes",
                                   join_keys: [enjoyer_id: :id, podcast_id: :id]
    many_to_many :episodes_i_like, Episode,
                                   join_through: "likes",
                                   join_keys: [enjoyer_id: :id, episode_id: :id]
    many_to_many :chapters_i_like, Chapter,
                                   join_through: "likes",
                                   join_keys: [enjoyer_id: :id, chapter_id: :id]
    many_to_many :categories_i_like, Category,
                                     join_through: "likes",
                                     join_keys: [enjoyer_id: :id, category_id: :id]
    many_to_many :categories_i_follow, Category,
                                       join_through: "follows",
                                       join_keys: [follower_id: :id, category_id: :id]

    has_many :following, Follow, on_delete: :delete_all
    has_many :followeds, Follow, foreign_key: :follower_id, on_delete: :delete_all
    has_many :liking, Like, on_delete: :delete_all
    has_many :liked, Like, foreign_key: :enjoyer_id, on_delete: :delete_all
    has_many :subscriptions, Subscription, on_delete: :delete_all
  end


  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:name, :username, :email, :admin, :podcaster, :email_confirmed,
                     :share_subscriptions, :share_follows, :pro_until, :billing_address,
                     :payment_reference, :paper_bill, :elastic])
    |> validate_required([:name, :username, :email])
    |> validate_length(:username, min: 3, max: 30)
    |> unique_constraint(:username)
    |> unique_constraint(:email)
    |> validate_length(:name, min: 3, max: 100)
    |> validate_length(:email, min: 5, max: 100)
  end

  def self_change_changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:podcaster, :email, :name, :username, :share_follows, :share_subscriptions,
                     :billing_address, :paper_bill])
    |> validate_required([:email, :name, :username])
    |> validate_length(:name, min: 3, max: 100)
    |> validate_length(:email, min: 5, max: 100)
    |> validate_length(:username, min: 3, max: 30)
    |> unique_constraint(:username)
    |> unique_constraint(:email)
  end

  def registration_changeset(struct, params) do
    struct
    |> cast(params, [:name, :username, :email, :podcaster, :share_subscriptions, :share_follows,
                     :password, :password_confirmation, :bot_check])
    |> validate_required([:name, :username, :email, :password, :password_confirmation, :bot_check])
    |> validate_length(:username, min: 3, max: 30)
    |> validate_confirmation(:password)
    |> validate_bot_check(params)
    |> unique_constraint(:username)
    |> unique_constraint(:email)
    |> validate_length(:name, min: 3, max: 100)
    |> validate_length(:email, min: 5, max: 100)
    |> validate_length(:password, min: 6, max: 100)
    |> put_pass_hash()
  end

  defp validate_bot_check(changeset, params) do
    if params["bot_check"] == "42" do
      changeset
    else
      add_error(changeset, :bot_check, "It seems, you are a bot! 🤣")
    end
  end

  def password_update_changeset(struct, params) do
    struct
    |> cast(params, [:password, :password_confirmation])
    |> validate_required([:password, :password_confirmation])
    |> validate_confirmation(:password)
    |> validate_length(:password, min: 6, max: 100)
    |> put_pass_hash()
  end

  def request_login_changeset(struct, params) do
    struct
    |> cast(params, [:email])
    |> validate_required([:email])
    |> validate_length(:email, min: 5, max: 100)
  end


  def put_pass_hash(changeset) do
    case changeset do
      %Ecto.Changeset{valid?: true, changes: %{password: pass}} ->
        put_change(changeset, :password_hash, Bcrypt.hash_pwd_salt(pass))
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
        {:ok, Repo.delete!(like)}
    end
  end


  def follow(user_id, current_user_id) do
    case Repo.get_by(Follow, follower_id: current_user_id,
                             user_id: user_id) do
      nil ->
        %Follow{follower_id: current_user_id, user_id: user_id}
        |> Repo.insert
      follow ->
        {:ok, Repo.delete!(follow)}
    end
  end


  def follower_mailboxes(user_id) do
    Repo.all(from l in Follow, where: l.user_id == ^user_id,
                               select: [:follower_id])
    |> Enum.map(fn(user) ->  "mailboxes:" <> Integer.to_string(user.follower_id) end)
  end


  def likes(id) do
    from(l in Like, where: l.user_id == ^id)
    |> Repo.aggregate(:count)
    |> Integer.to_string
  end


  def follows(id) do
    from(f in Follow, where: f.user_id == ^id)
    |> Repo.aggregate(:count)
    |> Integer.to_string
  end


  def popularity(id) do
    followers = from(f in Follow, where: f.user_id == ^id)
    |> Repo.aggregate(:count)

    likes = from(l in Like, where: l.user_id == ^id)
    |> Repo.aggregate(:count)

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


  def subscribed_persona_ids(user_id) do
    case Repo.all(from f in Follow, where: f.follower_id == ^user_id and
                                           not is_nil(f.persona_id),
                                    select: f.persona_id) do
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


  def update_search_index(id) do
    user = Repo.get(User, id)
    put("/panoptikum_" <> Application.get_env(:pan, :environment) <> "/users/" <> Integer.to_string(id),
        [name: user.name,
         username: user.username,
         url: user_frontend_path(PanWeb.Endpoint, :show, id)])
  end


  def delete_search_index(id) do
    delete("http://127.0.0.1:9200/panoptikum_" <> Application.get_env(:pan, :environment) <>
           "/users/" <> Integer.to_string(id))
  end


  def delete_search_index_orphans() do
    user_ids = (from c in User, select: c.id)
               |> Repo.all()

    max_user_id = Enum.max(user_ids)
    all_ids = Range.new(1, max_user_id) |> Enum.to_list()
    deleted_ids = all_ids -- user_ids

    for deleted_id <- deleted_ids do
      delete_search_index(deleted_id)
    end
  end


  def pro_expiration() do
    in_seven_days = Timex.now()
                    |> Timex.shift(days: 7)
    in_six_days = Timex.now()
                  |> Timex.shift(days: 6)

    emails = from(u in User, where: u.pro_until >= ^in_six_days and
                                    u.pro_until <= ^in_seven_days,
                             select: u.email)
             |> Repo.all()

    for email <- emails do
      Pan.Email.pro_expiration_notification(email)
      |> Pan.Mailer.deliver_now()
    end
  end
end
