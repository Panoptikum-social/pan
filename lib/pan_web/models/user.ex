defmodule PanWeb.User do
  use PanWeb, :model
  alias Pan.Repo

  alias PanWeb.{
    Category,
    Chapter,
    Community,
    Episode,
    FeedBacklog,
    Follow,
    Invoice,
    Language,
    Like,
    Manifestation,
    Opml,
    Persona,
    Podcast,
    Recommendation,
    User,
    Subscription,
    Moderation
  }

  @minimum_password_length 10

  # Retention policy, see the "User management and data retention" backlog item
  # and the privacy page: accounts without a real login for two years are
  # announced by mail and may be deleted once they have been marked for
  # deletion for a grace period of 30 days.
  @inactive_after_days 2 * 365
  @deletion_grace_days 30
  @unverified_grace_days 30

  @retention_filters [:unverified, :never_logged_in, :inactive, :unmarked, :marked, :deletable]

  schema "users" do
    field(:name, :string)
    field(:username, :string)
    field(:password, :string, virtual: true)
    field(:password_confirmation, :string, virtual: true)
    field(:password_hash, :string, redact: true)
    field(:email, :string)
    field(:admin, :boolean, default: false)
    field(:podcaster, :boolean, default: false)
    field(:moderator, :boolean, default: false)
    field(:email_verified, :boolean, default: false)
    field(:last_login_at, :naive_datetime)
    field(:marked_for_deletion_at, :naive_datetime)
    field(:share_subscriptions, :boolean, default: false)
    field(:share_follows, :boolean, default: false)
    field(:bot_check, :integer, virtual: true)
    timestamps()

    has_many(:backlog_feeds, FeedBacklog, on_delete: :delete_all)
    has_many(:manifestations, Manifestation, on_delete: :delete_all)
    has_many(:invoices, Invoice, on_delete: :nilify_all)
    has_many(:user_personas, Persona, foreign_key: :user_id)
    has_many(:recommendations, Recommendation, on_delete: :delete_all)
    has_many(:opmls, Opml, on_delete: :delete_all)

    many_to_many(:languages, Language, join_through: "users_languages", on_replace: :delete)

    many_to_many(:personas, Persona, join_through: "manifestations")

    many_to_many(:podcasts_i_subscribed, Podcast, join_through: "subscriptions")

    many_to_many(:users_i_like, User,
      join_through: "likes",
      join_keys: [enjoyer_id: :id, user_id: :id]
    )

    many_to_many(:users_i_follow, User,
      join_through: "follows",
      join_keys: [follower_id: :id, user_id: :id]
    )

    many_to_many(:personas_i_like, Persona,
      join_through: "likes",
      join_keys: [enjoyer_id: :id, persona_id: :id]
    )

    many_to_many(:personas_i_follow, Persona,
      join_through: "follows",
      join_keys: [follower_id: :id, persona_id: :id]
    )

    many_to_many(:podcasts_i_follow, Podcast,
      join_through: "follows",
      join_keys: [follower_id: :id, podcast_id: :id]
    )

    many_to_many(:podcasts_i_like, Podcast,
      join_through: "likes",
      join_keys: [enjoyer_id: :id, podcast_id: :id]
    )

    many_to_many(:episodes_i_like, Episode,
      join_through: "likes",
      join_keys: [enjoyer_id: :id, episode_id: :id]
    )

    many_to_many(:chapters_i_like, Chapter,
      join_through: "likes",
      join_keys: [enjoyer_id: :id, chapter_id: :id]
    )

    many_to_many(:categories_i_like, Category,
      join_through: "likes",
      join_keys: [enjoyer_id: :id, category_id: :id]
    )

    many_to_many(:categories_i_follow, Category,
      join_through: "follows",
      join_keys: [follower_id: :id, category_id: :id]
    )

    many_to_many(:communities_i_moderate, Community, join_through: "moderations")
    has_many(:categories_i_moderate, through: [:communities_i_moderate, :category])

    has_many(:following, Follow, on_delete: :delete_all)
    has_many(:followeds, Follow, foreign_key: :follower_id, on_delete: :delete_all)
    has_many(:liking, Like, on_delete: :delete_all)
    has_many(:liked, Like, foreign_key: :enjoyer_id, on_delete: :delete_all)
    has_many(:subscriptions, Subscription, on_delete: :delete_all)
    has_many(:moderations, Moderation, on_delete: :delete_all)
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :name,
      :username,
      :email,
      :admin,
      :podcaster,
      :moderator,
      :email_verified,
      :share_subscriptions,
      :share_follows
    ])
    |> validate_required([:name, :username, :email])
    |> validate_length(:username, min: 3, max: 30)
    |> unique_constraint(:username)
    |> unique_constraint(:email)
    |> validate_length(:name, min: 3, max: 100)
    |> validate_length(:email, min: 5, max: 100)
  end

  def self_change_changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :podcaster,
      :email,
      :name,
      :username,
      :share_follows,
      :share_subscriptions
    ])
    |> validate_required([:email, :name, :username])
    |> validate_length(:name, min: 3, max: 100)
    |> validate_length(:email, min: 5, max: 100)
    |> validate_length(:username, min: 3, max: 30)
    |> unique_constraint(:username)
    |> unique_constraint(:email)
  end

  def registration_changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :name,
      :username,
      :email,
      :podcaster,
      :share_subscriptions,
      :share_follows,
      :password,
      :password_confirmation,
      :bot_check
    ])
    |> validate_required([
      :name,
      :username,
      :email,
      :password,
      :password_confirmation,
      :bot_check
    ])
    |> validate_length(:username, min: 3, max: 30)
    |> validate_confirmation(:password)
    |> validate_bot_check(params)
    |> unique_constraint(:username)
    |> unique_constraint(:email)
    |> validate_length(:name, min: 3, max: 100)
    |> validate_length(:email, min: 5, max: 100)
    |> validate_length(:password, min: @minimum_password_length, max: 100)
    |> put_pass_hash()
  end

  defp validate_bot_check(changeset, params) do
    if params["bot_check"] == "42" do
      changeset
    else
      add_error(changeset, :bot_check, "That's not right.")
    end
  end

  def password_update_changeset(struct, params) do
    struct
    |> cast(params, [:password, :password_confirmation])
    |> validate_required([:password, :password_confirmation])
    |> validate_confirmation(:password)
    |> validate_length(:password, min: @minimum_password_length, max: 100)
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
    case Repo.get_by(Like,
           enjoyer_id: current_user_id,
           user_id: user_id
         ) do
      nil ->
        %Like{enjoyer_id: current_user_id, user_id: user_id}
        |> Repo.insert()

      like ->
        {:ok, Repo.delete!(like)}
    end
  end

  def follow(user_id, current_user_id) do
    case Repo.get_by(Follow,
           follower_id: current_user_id,
           user_id: user_id
         ) do
      nil ->
        %Follow{follower_id: current_user_id, user_id: user_id}
        |> Repo.insert()

      follow ->
        {:ok, Repo.delete!(follow)}
    end
  end

  def follower_mailboxes(user_id) do
    Repo.all(
      from(l in Follow,
        where: l.user_id == ^user_id,
        select: [:follower_id]
      )
    )
    |> Enum.map(fn user -> "mailboxes:" <> Integer.to_string(user.follower_id) end)
  end

  def likes(id) do
    from(l in Like, where: l.user_id == ^id)
    |> Repo.aggregate(:count)
    |> Integer.to_string()
  end

  def follows(id) do
    from(f in Follow, where: f.user_id == ^id)
    |> Repo.aggregate(:count)
    |> Integer.to_string()
  end

  def popularity(id) do
    followers =
      from(f in Follow, where: f.user_id == ^id)
      |> Repo.aggregate(:count)

    likes =
      from(l in Like, where: l.user_id == ^id)
      |> Repo.aggregate(:count)

    Integer.to_string(followers + likes)
  end

  def subscribed_user_ids(user_id) do
    case Repo.all(
           from(f in Follow,
             where:
               f.follower_id == ^user_id and
                 not is_nil(f.user_id),
             select: f.user_id
           )
         ) do
      [] ->
        ["0"]

      array ->
        Enum.map(array, fn id -> Integer.to_string(id) end)
    end
  end

  def subscribed_persona_ids(user_id) do
    case Repo.all(
           from(f in Follow,
             where:
               f.follower_id == ^user_id and
                 not is_nil(f.persona_id),
             select: f.persona_id
           )
         ) do
      [] ->
        ["0"]

      array ->
        Enum.map(array, fn id -> Integer.to_string(id) end)
    end
  end

  def subscribed_category_ids(user_id) do
    case Repo.all(
           from(f in Follow,
             where:
               f.follower_id == ^user_id and
                 not is_nil(f.category_id),
             select: f.category_id
           )
         ) do
      [] ->
        ["0"]

      array ->
        Enum.map(array, fn id -> Integer.to_string(id) end)
    end
  end

  def subscribed_podcast_ids(user_id) do
    case Repo.all(
           from(f in Follow,
             where:
               f.follower_id == ^user_id and
                 not is_nil(f.podcast_id),
             select: f.podcast_id
           )
         ) do
      [] ->
        ["0"]

      array ->
        Enum.map(array, fn id -> Integer.to_string(id) end)
    end
  end

  def get_for_show(id) do
    Repo.get!(User, id)
    |> Repo.preload([:users_i_like, :categories_i_like, :podcasts_i_subscribed])
  end

  def get_by_id(id) do
    Repo.get!(User, id)
  end

  def get_by_id_with_personas(id) do
    Repo.get!(User, id)
    |> Repo.preload(:personas)
  end

  @doc """
  Sets the languages a user speaks, for the "restrict search to my
  languages" feature. `representative_ids` are the ids picked from
  `Language.grouped/0` (one per real language, e.g. the "German" option);
  each is expanded to every underlying shortcode row (`de`, `de-DE`, `de-AT`,
  ...) before saving, so a later search filter needs no further expansion —
  `user.languages` already holds the full matching set.
  """
  def update_languages(user, representative_ids) do
    languages =
      representative_ids
      |> Language.expand_group_ids()
      |> then(&from(l in Language, where: l.id in ^&1))
      |> Repo.all()

    user
    |> Repo.preload(:languages)
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.put_assoc(:languages, languages)
    |> Repo.update()
  end

  def retention_filters, do: @retention_filters
  def deletion_grace_days, do: @deletion_grace_days

  # Admins and moderators are never part of the retention tooling.
  defp regular_users do
    from(u in User,
      where: not coalesce(u.admin, false) and not coalesce(u.moderator, false)
    )
  end

  defp days_ago(days), do: NaiveDateTime.add(Pan.Parser.MyDateTime.now(), -days, :day)

  # Every filter restricts the users further, so a list of filters is an AND.
  # `search` is a text that has to be contained in the username or the email.
  defp retention_query(filters, search \\ "") do
    Enum.reduce(filters, regular_users(), &retention_filter(&2, &1))
    |> retention_search(String.trim(search))
  end

  defp retention_search(query, ""), do: query

  defp retention_search(query, search) do
    pattern = "%" <> String.replace(search, ~r/[\\%_]/, "\\\\\\0") <> "%"
    from(u in query, where: ilike(u.username, ^pattern) or ilike(u.email, ^pattern))
  end

  defp retention_filter(query, :unverified),
    do: from(u in query, where: not coalesce(u.email_verified, false))

  defp retention_filter(query, :never_logged_in),
    do: from(u in query, where: is_nil(u.last_login_at))

  defp retention_filter(query, :inactive) do
    from(u in query,
      where: not is_nil(u.last_login_at) and u.last_login_at < ^days_ago(@inactive_after_days)
    )
  end

  defp retention_filter(query, :unmarked),
    do: from(u in query, where: is_nil(u.marked_for_deletion_at))

  defp retention_filter(query, :marked),
    do: from(u in query, where: not is_nil(u.marked_for_deletion_at))

  defp retention_filter(query, :deletable) do
    from(u in query,
      where:
        not is_nil(u.marked_for_deletion_at) and
          u.marked_for_deletion_at <= ^days_ago(@deletion_grace_days)
    )
  end

  def retention_users(filters, search, sort_by, sort_order, limit, offset) do
    from(u in retention_query(filters, search),
      order_by: [{^sort_order, field(u, ^sort_by)}, asc: u.id],
      limit: ^limit,
      offset: ^offset,
      select: %{
        id: u.id,
        username: u.username,
        email: u.email,
        email_verified: u.email_verified,
        inserted_at: u.inserted_at,
        last_login_at: u.last_login_at,
        marked_for_deletion_at: u.marked_for_deletion_at
      }
    )
    |> Repo.all()
  end

  def count_retention_users(filters, search) do
    retention_query(filters, search) |> Repo.aggregate(:count)
  end

  @doc "Marks the given users (not admins or moderators) for deletion; returns how many were marked."
  def mark_for_deletion(ids) do
    {count, _} =
      from(u in regular_users(), where: u.id in ^ids and is_nil(u.marked_for_deletion_at))
      |> Repo.update_all(set: [marked_for_deletion_at: Pan.Parser.MyDateTime.now()])

    count
  end

  @doc "Removes the deletion mark from the given users; returns how many were unmarked."
  def unmark_for_deletion(ids) do
    {count, _} =
      from(u in regular_users(), where: u.id in ^ids)
      |> Repo.update_all(set: [marked_for_deletion_at: nil])

    count
  end

  @doc """
  The id of the lowest-id user the retention policy applies to and who has not
  been noticed yet, or nil. Never-verified accounts qualify after
  #{@unverified_grace_days} days (a fresh signup is still verifying), verified ones
  after two years without a login (their signup date counts if they never
  logged in). Users in `excluded_ids` are skipped.
  """
  def next_retention_candidate_id(excluded_ids \\ []) do
    inactive_cutoff = days_ago(@inactive_after_days)
    unverified_cutoff = days_ago(@unverified_grace_days)

    from(u in regular_users(),
      where:
        is_nil(u.marked_for_deletion_at) and u.id not in ^excluded_ids and
          ((not coalesce(u.email_verified, false) and u.inserted_at < ^unverified_cutoff) or
             coalesce(u.last_login_at, u.inserted_at) < ^inactive_cutoff),
      order_by: [asc: u.id],
      limit: 1,
      select: u.id
    )
    |> Repo.one()
  end

  @doc """
  Mails a deletion notice with a login link (valid for the grace period) to the
  given users (not admins or moderators). The reasons in the mail come from the
  user's data. A user is marked for deletion only once the mail was accepted, an
  existing mark date is kept. Returns how many notices were sent and failed.
  """
  def send_retention_notices(ids) do
    results =
      from(u in regular_users(), where: u.id in ^ids)
      |> Repo.all()
      |> Enum.map(&send_retention_notice/1)

    %{sent: Enum.count(results, &(&1 == :ok)), failed: Enum.count(results, &(&1 == :error))}
  end

  defp send_retention_notice(user) do
    token = PanWeb.Auth.sign_token(:retention_notice, user.id)
    delete_after = Date.add(Date.utc_today(), @deletion_grace_days)

    case user
         |> Pan.Email.retention_notice_html_email(token, retention_reasons(user), delete_after)
         |> Pan.Mailer.deliver() do
      {:ok, _receipt} ->
        mark_for_deletion([user.id])
        :ok

      {:error, _reason} ->
        :error
    end
  end

  defp retention_reasons(user) do
    inactive? =
      NaiveDateTime.compare(
        user.last_login_at || user.inserted_at,
        days_ago(@inactive_after_days)
      ) == :lt

    [inactive: inactive?, unverified: !user.email_verified]
    |> Enum.filter(fn {_reason, applies?} -> applies? end)
    |> Keyword.keys()
  end

  @doc """
  Deletes those of the given users that have been marked for deletion for at
  least the grace period (and are not admins or moderators); returns how many
  were deleted. Everything else in `ids` is ignored.
  """
  def delete_deletable(ids) do
    from(u in retention_query([:deletable]), where: u.id in ^ids)
    |> Repo.all()
    |> Enum.map(&PanWeb.Admin.QueryBuilder.delete(User, &1))
    |> length()
  end
end
