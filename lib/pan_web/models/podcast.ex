defmodule PanWeb.Podcast do
  use Pan.Web, :model
  alias Pan.Repo
  alias PanWeb.{Category, Engagement, Episode, Feed, Follow, Gig, Image, Language, Like,
                Persona, Podcast, Recommendation, RssFeed, Subscription, User }
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
    field :failure_count, :integer
    field :unique_identifier, Ecto.UUID
    field :episodes_count, :integer
    field :followers_count, :integer
    field :likes_count, :integer
    field :subscriptions_count, :integer
    field :latest_episode_publishing_date, :naive_datetime
    field :publication_frequency, :float
    field :manually_updated_at, :naive_datetime
    field :elastic, :boolean
    field :last_error_message, :string
    field :last_error_occured, :naive_datetime
    timestamps()

    has_many :episodes, Episode, on_delete: :delete_all
    has_many :feeds, Feed, on_delete: :delete_all
    has_many :rss_feeds, RssFeed, on_delete: :delete_all
    has_many :recommendations, Recommendation, on_delete: :delete_all
    has_many :engagements, Engagement, on_delete: :delete_all
    has_many :thumbnails, Image, on_delete: :delete_all

    many_to_many :categories, Category, join_through: "categories_podcasts",
                                        on_delete: :delete_all
    many_to_many :contributors, Persona, join_through: "engagements"
    many_to_many :listeners, User, join_through: "subscriptions",
                                   on_delete: :delete_all
    many_to_many :likers, User, join_through: "likes",
                                join_keys: [podcast_id: :id, enjoyer_id: :id],
                                on_delete: :delete_all
    many_to_many :followers, User, join_through: "follows",
                                   join_keys: [podcast_id: :id, follower_id: :id],
                                   on_delete: :delete_all
    many_to_many :languages, Language, join_through: "languages_podcasts",
                                       on_delete: :delete_all
  end


  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:title, :website, :last_build_date, :explicit, :payment_link_title,
                     :payment_link_url, :unique_identifier, :image_title, :image_url, :description,
                     :summary, :update_paused, :blocked, :retired, :updated_at, :update_intervall,
                     :next_update, :episodes_count, :followers_count, :likes_count,
                     :subscriptions_count, :latest_episode_publishing_date, :publication_frequency,
                     :failure_count, :manually_updated_at, :elastic, :last_error_message,
                     :last_error_occured])
    |> validate_required([:title, :update_intervall, :next_update])
    |> unique_constraint(:title)
  end


  def like(podcast_id, user_id) do
    response =
      case Like.find_podcast_like(user_id, podcast_id) do
        nil ->
          %Like{enjoyer_id: user_id, podcast_id: podcast_id}
          |> Repo.insert
        like ->
          {:ok, Repo.delete!(like)}
      end

    Podcast.update_likes_count(podcast_id)
    response
  end


  def follow(podcast_id, user_id) do
    response =
      case Repo.get_by(Follow, follower_id: user_id,
                               podcast_id: podcast_id) do
        nil ->
          %Follow{follower_id: user_id, podcast_id: podcast_id}
          |> Repo.insert
        follow ->
          {:ok, Repo.delete!(follow)}
      end

    Podcast.update_followers_count(podcast_id)
    response
  end


  def subscribe(podcast_id, user_id) do
    case Repo.get_by(Subscription, user_id: user_id,
                             podcast_id: podcast_id) do
      nil ->
        %Subscription{user_id: user_id, podcast_id: podcast_id}
        |> Repo.insert
      subscription ->
        {:ok, Repo.delete!(subscription)}
    end
  end


  def follower_mailboxes(podcast_id) do
    Repo.all(from l in Follow, where: l.podcast_id == ^podcast_id,
                               select: [:follower_id])
    |> Enum.map(fn(user) ->  "mailboxes:" <> Integer.to_string(user.follower_id) end)
  end


  def latest do
    from(p in Podcast, order_by: [fragment("? DESC NULLS LAST", p.inserted_at)],
                       where: is_false(p.blocked),
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
    |> hd()

    if engagement, do: engagement.persona
  end

  def author_name(podcast) do
    author = author(podcast)
    if author, do: author.name
  end


  def import_stale_podcasts() do
    podcasts = from(p in Podcast, where: p.next_update <= ^Timex.now() and
                                         is_false(p.update_paused) and is_false(p.retired),
                                  order_by: [asc: :next_update],
                                  limit: 2000)
               |> Repo.all()
    Logger.info "=== Started importing #{length(podcasts)} podcasts ==="

    for podcast <- podcasts, do: Pan.Updater.Podcast.import_new_episodes(podcast)
    Logger.info "=== Import job finished ==="
  end


  def update_search_index(id) do
    podcast = Repo.get(Podcast, id)

    if podcast.blocked == true do
      delete_search_index(id)
    else
      put("/panoptikum_" <> Application.get_env(:pan, :environment) <> "/podcasts/" <> Integer.to_string(id),
          [title:       podcast.title,
           description: podcast.description,
           summary:     podcast.summary,
           url:         podcast_frontend_path(PanWeb.Endpoint, :show, id)])
    end
  end


  def remove_unwanted_references(id) do
    podcast = Repo.get(Podcast, id)

    if podcast.blocked == true do
      episode_ids = from(e in Episode, where: e.podcast_id == ^id,
                                       select: e.id)
                    |> Repo.all()

      from(g in Gig, where: g.episode_id in ^episode_ids)
      |> Repo.delete_all()

      for episode_id <- episode_ids do
        Episode.delete_search_index(episode_id)
      end

      from(e in Engagement, where: e.podcast_id == ^id)
      |> Repo.delete_all()

      from(cp in PanWeb.CategoryPodcast, where: cp.podcast_id == ^id)
      |> Repo.delete_all()

      from(f in PanWeb.Follow, where: f.podcast_id == ^id)
      |> Repo.delete_all()

      from(lp in "languages_podcasts", where: lp.podcast_id == ^id)
      |> Repo.delete_all()

      from(r in PanWeb.Recommendation, where: r.podcast_id == ^id)
      |> Repo.delete_all()

      from(r in PanWeb.Recommendation, where: r.episode_id in ^episode_ids)
      |> Repo.delete_all()

      chapter_ids = from(c in PanWeb.Chapter, where: c.episode_id in ^episode_ids,
                                              select: c.id)
                    |> Repo.all()

      from(r in PanWeb.Recommendation, where: r.chapter_id in ^chapter_ids)
      |> Repo.delete_all()

      from(s in PanWeb.Subscription, where: s.podcast_id == ^id)
      |> Repo.delete_all()
    end
  end


  def derive_intervall(id) do
    last_update = from(e in Episode, where: e.podcast_id == ^id,
                                     order_by: [desc: :updated_at],
                                     limit: 1,
                                     select: e.updated_at)
                  |> Repo.all()
                  |> hd()

    hours = Timex.diff(Timex.now(), Timex.to_datetime(last_update), :hours)

    # approximate solution for u_i*(u_i+1)/2 = hours
    update_intervall = round(:math.sqrt(8 * hours) / 2)
    next_update = Timex.now()
                  |> Timex.shift(hours: update_intervall)

    Repo.get(Podcast, id)
    |> Podcast.changeset(%{update_intervall: update_intervall,
                           next_update:      next_update})
    |> Repo.update()
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


  def delete_search_index(id) do
    delete("http://127.0.0.1:9200/panoptikum_" <> Application.get_env(:pan, :environment) <>
           "/podcasts/" <> Integer.to_string(id))
  end


  def delete_search_index_orphans() do
    podcast_ids = (from c in Podcast, select: c.id)
                  |> Repo.all()

    max_podcast_id = Enum.max(podcast_ids)
    all_ids = Range.new(1, max_podcast_id) |> Enum.to_list()
    deleted_ids = all_ids -- podcast_ids

    for {deleted_id, index} <- Enum.with_index(deleted_ids) do
      IO.puts Integer.to_string((length(deleted_ids) - index))
      delete_search_index(deleted_id)
    end
  end


  def update_counters(podcast_changeset) do
    podcast_id = podcast_changeset.data.id

    episodes_count = where(Episode, podcast_id: ^podcast_id)
                     |> Repo.aggregate(:count, :id)

    likes_count = where(Like, podcast_id: ^podcast_id)
                  |> Repo.aggregate(:count, :id)

    followers_count = where(Follow, podcast_id: ^podcast_id)
                      |> Repo.aggregate(:count, :id)

    subscriptions_count = where(Subscription, podcast_id: ^podcast_id)
                          |> Repo.aggregate(:count, :id)

    episode_publishing_dates = from(e in Episode, where: e.podcast_id == ^podcast_id,
                                                  select: [e.publishing_date, e.inserted_at])
                               |> Repo.all()

    latest_episode_publishing_date = Enum.map(episode_publishing_dates, &best_effort_for_pubdate(&1))
                                     |> Enum.max()
    first_episode_publishing_date =  Enum.map(episode_publishing_dates, &best_effort_for_pubdate(&1))
                                     |> Enum.max()

    publication_frequency =
      if episodes_count > 1 && latest_episode_publishing_date && first_episode_publishing_date do
        NaiveDateTime.diff(latest_episode_publishing_date, first_episode_publishing_date, :second) /
                      (episodes_count - 1) / 86_400
      else
        0.0
      end

    podcast_changeset
    |> put_change(:episodes_count, episodes_count)
    |> put_change(:likes_count, likes_count)
    |> put_change(:followers_count, followers_count)
    |> put_change(:subscriptions_count, subscriptions_count)
    |> put_change(:latest_episode_publishing_date, latest_episode_publishing_date)
    |> put_change(:publication_frequency, publication_frequency)
  end


  defp best_effort_for_pubdate([publishing_date, inserted_at]) do
    publishing_date || inserted_at
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


  def cache_missing_thumbnail_images() do
    podcasts_missing_thumbnails =
      (from p in Podcast, left_join: i in assoc(p, :thumbnails),
                          where: is_nil(i.podcast_id) and not is_nil(p.image_url))
      |> Ecto.Query.limit(3000)
      |> Repo.all

    for podcast <- podcasts_missing_thumbnails do
      Podcast.cache_thumbnail_image(podcast)
    end
  end


  def cache_thumbnail_image(podcast) do
    with {:error, _} <- Image.download_thumbnail("podcast", podcast.id, podcast.image_url) do
      Podcast.clear_image_url(podcast)
    end
  end


  def clear_image_url(podcast) do
    podcast
    |> Podcast.changeset(%{image_url: nil})
    |> Repo.update()
  end
end
