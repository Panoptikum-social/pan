defmodule PanWeb.Podcast do
  use Pan.Web, :model
  alias Pan.Repo
  alias PanWeb.Like
  alias PanWeb.Follow
  alias PanWeb.Subscription
  alias PanWeb.Podcast
  alias PanWeb.Engagement
  alias PanWeb.Episode
  require Logger

  schema "podcasts" do
    field :title, :string
    field :website, :string
    field :description, :string
    field :summary, :string
    field :image_title, :string
    field :image_url, :string
    field :last_build_date, :naive_datetime
    field :payment_link_title, :string
    field :payment_link_url, :string
    field :explicit, :boolean, default: false
    field :blocked, :boolean, default: false
    field :update_paused, :boolean, default: false
    field :update_intervall, :integer
    field :next_update, :naive_datetime
    field :retired, :boolean, default: false
    field :unique_identifier, Ecto.UUID
    field :episodes_count, :integer
    field :followers_count, :integer
    field :likes_count, :integer
    field :subscriptions_count, :integer
    field :latest_episode_publishing_date, :naive_datetime
    field :publication_frequency, :float
    timestamps()

    has_many :episodes, PanWeb.Episode, on_delete: :delete_all
    has_many :feeds, PanWeb.Feed, on_delete: :delete_all
    has_many :subscriptions, PanWeb.Subscription
    has_many :engagements, PanWeb.Engagement

    has_many :recommendations, PanWeb.Recommendation, on_delete: :delete_all
    many_to_many :categories, PanWeb.Category, join_through: "categories_podcasts",
                                            on_delete: :delete_all
    many_to_many :contributors, PanWeb.Persona, join_through: "engagements",
                                             on_delete: :delete_all
    many_to_many :listeners, PanWeb.User, join_through: "subscriptions",
                                       on_delete: :delete_all
    many_to_many :followers, PanWeb.User, join_through: "likes",
                                       join_keys: [podcast_id: :id, enjoyer_id: :id]
    many_to_many :languages, PanWeb.Language, join_through: "languages_podcasts",
                                           on_delete: :delete_all
  end


  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:title, :website, :last_build_date, :explicit, :payment_link_title,
                     :payment_link_url, :unique_identifier, :image_title, :image_url, :description,
                     :summary, :update_paused, :blocked, :retired, :updated_at, :update_intervall,
                     :next_update, :episodes_count, :followers_count, :likes_count,
                     :subscriptions_count, :latest_episode_publishing_date, :publication_frequency])
    |> validate_required([:title, :update_intervall, :next_update])
    |> unique_constraint(:title)
  end


  def like(podcast_id, user_id) do
    case Like.find_podcast_like(user_id, podcast_id) do
      nil ->
        %Like{enjoyer_id: user_id, podcast_id: podcast_id}
        |> Repo.insert
      like ->
        Repo.delete!(like)
    end
    Podcast.update_likes_count(podcast_id)
  end


  def follow(podcast_id, user_id) do
    case Repo.get_by(Follow, follower_id: user_id,
                             podcast_id: podcast_id) do
      nil ->
        %Follow{follower_id: user_id, podcast_id: podcast_id}
        |> Repo.insert
      like ->
        Repo.delete!(like)
    end
    Podcast.update_followers_count(podcast_id)
  end


  def subscribe(podcast_id, user_id) do
    case Repo.get_by(Subscription, user_id: user_id,
                             podcast_id: podcast_id) do
      nil ->
        %Subscription{user_id: user_id, podcast_id: podcast_id}
        |> Repo.insert
      like ->
        Repo.delete!(like)
    end
  end


  def follower_mailboxes(podcast_id) do
    Repo.all(from l in Follow, where: l.podcast_id == ^podcast_id,
                               select: [:follower_id])
    |> Enum.map(fn(user) ->  "mailboxes:" <> Integer.to_string(user.follower_id) end)
  end


  def latest do
    from(p in Podcast, order_by: [desc: :inserted_at],
                       where: is_nil(p.blocked) or p.blocked == false,
                       join: e in assoc(p, :engagements),
                       where: e.role == "author",
                       join: persona in assoc(e, :persona),
                       select: %{id: p.id,
                                 title: p.title,
                                 inserted_at: p.inserted_at,
                                 description: p.description,
                                 author_id: persona.id,
                                 author_name: persona.name},
                       limit: 10)
    |> Repo.all()
  end


  def author(podcast) do
    engagement = from(Engagement, where: [role: "author",
                                  podcast_id: ^podcast.id],
                                  preload: :persona,
                                  limit: 1)
    |> Repo.all()
    |> List.first()

    if engagement, do: engagement.persona
  end

  def author_name(podcast) do
    author = author(podcast)
    if author, do: author.name
  end


  def import_stale_podcasts() do
    podcasts = from(p in Podcast, where: p.next_update <= ^Timex.now() and
                                         (is_nil(p.update_paused) or p.update_paused == false) and
                                         (is_nil(p.retired) or p.retired == false),
                                  order_by: [asc: :next_update])
               |> Repo.all()
    Logger.info "=== Started importing " <> to_string(length(podcasts)) <> " podcasts ==="

    for podcast <- podcasts do
      delta_import_one(podcast, nil)
    end
    Logger.info "=== Import job finished ==="
  end


  def delta_import_one(podcast, current_user \\ nil) do
    podcast = Repo.get(Podcast, podcast.id)
    next_update = Timex.now()
                  |> Timex.shift(hours: podcast.update_intervall + 1)

    Podcast.changeset(podcast, %{update_intervall: podcast.update_intervall + 1,
                                 next_update:      next_update})
    |> Repo.update()

    notification = case Pan.Parser.Podcast.delta_import(podcast.id) do
      {:ok, _} ->
        %{content: "<i class='fa fa-refresh'></i> " <> Integer.to_string(podcast.id) <>
                    " <i class='fa fa-podcast'></i> " <> podcast.title,
          type: "success",
          user_name: current_user && current_user.name}

      {:error, message} ->
        %{content: "Error: " <> message <> " | " <>
                   "<i class='fa fa-refresh'></i> " <> Integer.to_string(podcast.id) <>
                   " <i class='fa fa-podcast'></i> " <> podcast.title,
          type: "danger",
          user_name: current_user && current_user.name}
    end

    if current_user do
      PanWeb.Endpoint.broadcast "mailboxes:" <> Integer.to_string(current_user.id),
                             "notification", notification
    end
  end


  def update_search_index(id) do
    podcast = Repo.get(Podcast, id)

    unless podcast.blocked == true do
      put("/panoptikum_" <> Application.get_env(:pan, :environment) <> "/podcasts/" <> Integer.to_string(id),
          [title:       podcast.title,
           description: podcast.description,
           summary:     podcast.summary,
           url:         podcast_frontend_path(PanWeb.Endpoint, :show, id)])
    end
  end


  def derive_intervall(id) do
    last_update = from(e in Episode, where: e.podcast_id == ^id,
                                     order_by: [desc: :updated_at],
                                     limit: 1,
                                     select: e.updated_at)
                  |> Repo.all()
                  |> List.first()

    hours = Timex.diff(Timex.now(), Timex.to_datetime(last_update), :hours)

    # approximate solution for u_i*(u_i+1)/2 = hours
    update_intervall = round(:math.sqrt(8 * hours) / 2)
    next_update = Timex.now()
                  |> Timex.shift(hours: update_intervall)

    changeset = Repo.get(Podcast, id)
    |> Podcast.changeset(%{update_intervall: update_intervall,
                           next_update:      next_update})
    |> Repo.update()

    IO.inspect changeset
  end


  def derive_all_intervalls() do
    podcast_ids = from(p in Podcast, where: is_nil(p.update_intervall),
                                     select: p.id)
                  |> Repo.all()

    for podcast_id <- podcast_ids do
      derive_intervall(podcast_id)
    end
  end


  def unretire_all() do
    podcast_ids = from(p in Podcast, where: p.retired == true,
                                     select: p.id)
                  |> Repo.all()

    for podcast_id <- podcast_ids do
      Repo.get(Podcast, podcast_id)
      |> Podcast.changeset(%{retired: false})
      |> Repo.update()
    end
  end


  def delete_search_index_orphans() do
    podcast_ids = (from c in Podcast, select: c.id)
                  |> Repo.all()

    max_podcast_id = Enum.max(podcast_ids)
    all_ids = Range.new(1, max_podcast_id) |> Enum.to_list()
    deleted_ids = all_ids -- podcast_ids

    for deleted_id <- deleted_ids do
      delete("http://127.0.0.1:9200/panoptikum_" <> Application.get_env(:pan, :environment) <>
             "/podcasts/" <> Integer.to_string(deleted_id))
    end
  end


  def update_counters(podcast) do
    podcast_id = podcast.data.id

    episodes_count = from(e in Episode, where: e.podcast_id == ^podcast_id)
                     |> Repo.aggregate(:count, :id)

    likes_count = from(l in Like, where: l.podcast_id == ^podcast_id)
                  |> Repo.aggregate(:count, :id)

    followers_count = from(f in Follow, where: f.podcast_id == ^podcast_id)
                      |> Repo.aggregate(:count, :id)

    subscriptions_count = from(s in Subscription, where: s.podcast_id == ^podcast_id)
                          |> Repo.aggregate(:count, :id)

    latest_episode_publishing_date = from(e in Episode, where: e.podcast_id == ^podcast_id)
                          |> Repo.aggregate(:max, :publishing_date)

    first_episode_publishing_date = from(e in Episode, where: e.podcast_id == ^podcast_id)
                                    |> Repo.aggregate(:min, :publishing_date)

    publication_frequency =
      if episodes_count > 1 && latest_episode_publishing_date && first_episode_publishing_date do
        NaiveDateTime.diff(latest_episode_publishing_date, first_episode_publishing_date, :second) /
                      (episodes_count - 1) / 86400
      else
        0.0
    end

    podcast
    |> put_change(:episodes_count, episodes_count)
    |> put_change(:likes_count, likes_count)
    |> put_change(:followers_count, followers_count)
    |> put_change(:subscriptions_count, subscriptions_count)
    |> put_change(:latest_episode_publishing_date, latest_episode_publishing_date)
    |> put_change(:publication_frequency, publication_frequency)
  end


  def update_all_counters do
    podcasts = Repo.all(Podcast)

    for podcast <- podcasts do
      Logger.info "\n\e[33m === Updating counter for podcast: #{podcast.id} #{podcast.title} ===\e[0m"

      podcast
      |> PanWeb.Podcast.changeset()
      |> PanWeb.Podcast.update_counters()
      |> Repo.update()
    end
  end


  def update_likes_count(id) do
    likes_count = from(l in Like, where: l.podcast_id == ^id)
                  |> Repo.aggregate(:count, :id)

    Repo.get!(Podcast, id)
    |> PanWeb.Podcast.changeset()
    |> put_change(:likes_count, likes_count)
    |> Repo.update()
  end


  def update_followers_count(id) do
    followers_count = from(f in Follow, where: f.podcast_id == ^id)
                      |> Repo.aggregate(:count, :id)

    Repo.get!(Podcast, id)
    |> PanWeb.Podcast.changeset()
    |> put_change(:followers_count, followers_count)
    |> Repo.update()
  end


  def update_subscriptions_count(id) do
    subscriptions_count = from(s in Subscription, where: s.podcast_id == ^id)
                          |> Repo.aggregate(:count, :id)

    Repo.get!(Podcast, id)
    |> PanWeb.Podcast.changeset()
    |> put_change(:subscriptions_count, subscriptions_count)
    |> Repo.update()
  end
end