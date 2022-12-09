defmodule PanWeb.Episode do
  use PanWeb, :model
  alias Pan.Repo
  alias PanWeb.{Category, Chapter, Enclosure, Episode, Gig, Like, Persona, Podcast, Recommendation}
  import Pan.Parser.MyDateTime, only: [now: 0]

  schema "episodes" do
    field(:title, :string)
    field(:link, :string)
    field(:publishing_date, :naive_datetime)
    field(:guid, :string)
    field(:description, Ecto.EctoText)
    field(:shownotes, Ecto.EctoText)
    field(:payment_link_title, :string)
    field(:payment_link_url, :string)
    field(:deep_link, :string)
    field(:duration, :string)
    field(:subtitle, :string)
    field(:summary, Ecto.EctoText)
    field(:image_title, :string)
    field(:image_url, :string)
    field(:full_text, :boolean)
    timestamps()

    belongs_to(:podcast, Podcast)

    has_many(:chapters, Chapter, on_delete: :delete_all, preload_order: [asc: :start])
    has_many(:enclosures, Enclosure, on_delete: :delete_all)
    has_many(:recommendations, Recommendation, on_delete: :delete_all)
    has_many(:gigs, Gig, on_delete: :delete_all)

    has_many(:likes, Like, on_delete: :delete_all)
    many_to_many(:contributors, Persona, join_through: "gigs")
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :title,
      :link,
      :publishing_date,
      :description,
      :shownotes,
      :duration,
      :payment_link_title,
      :payment_link_url,
      :deep_link,
      :subtitle,
      :summary,
      :guid,
      :podcast_id,
      :image_title,
      :image_url,
      :full_text
    ])
    |> validate_required([:title, :link, :publishing_date, :podcast_id])
    |> unique_constraint(:guid)
  end

  def like(episode_id, user_id) do
    case Repo.get_by(Like,
           enjoyer_id: user_id,
           episode_id: episode_id
         ) do
      nil ->
        %Like{enjoyer_id: user_id, episode_id: episode_id}
        |> Repo.insert()

      like ->
        {:ok, Repo.delete!(like)}
    end
  end

  def likes(id) do
    from(l in Like, where: l.episode_id == ^id)
    |> Repo.aggregate(:count)
    |> Integer.to_string()
  end

  def latest do
    latest(1, 1) |> List.first()
  end

  def latest(page, per_page) do
    from(e in PanWeb.Episode,
      order_by: [fragment("? DESC NULLS LAST", e.publishing_date)],
      join: p in assoc(e, :podcast),
      where:
        not p.blocked and
          e.publishing_date < ^now(),
      left_join: g in assoc(e, :gigs),
      where: g.role == "author",
      left_join: persona in assoc(g, :persona),
      select: %{
        id: e.id,
        title: e.title,
        subtitle: e.subtitle,
        publishing_date: e.publishing_date,
        duration: e.duration,
        author_id: persona.id,
        author_name: persona.name,
        podcast_id: e.podcast_id,
        podcast_title: p.title
      },
      limit: ^per_page,
      offset: (^page - 1) * ^per_page
    )
    |> Repo.all()
  end

  def latest_episodes_by_podcast_ids(podcast_ids, page, per_page) do
    from(e in Episode,
      order_by: [fragment("? DESC NULLS LAST", e.publishing_date)],
      join: p in assoc(e, :podcast),
      where:
        not p.blocked and
          e.publishing_date < ^now() and
          e.podcast_id in ^podcast_ids,
      left_join: g in assoc(e, :gigs),
      where: g.role == "author",
      left_join: persona in assoc(g, :persona),
      select: %{
        id: e.id,
        title: e.title,
        subtitle: e.subtitle,
        publishing_date: e.publishing_date,
        duration: e.duration,
        author_id: persona.id,
        author_name: persona.name,
        podcast_id: e.podcast_id,
        podcast_title: p.title
      },
      limit: ^per_page,
      offset: (^page - 1) * ^per_page
    )
    |> Repo.all()
  end

  def clear_image_url(episode) do
    episode
    |> Episode.changeset(%{image_url: nil, link: episode.link || "https://example.com"})
    |> Repo.update()
  end

  def get_by_podcast_id(podcast_id, page, per_page) do
    from(e in Episode,
      where: e.podcast_id == ^podcast_id,
      order_by: [fragment("? DESC NULLS LAST", e.publishing_date)],
      preload: [[gigs: :persona]],
      limit: ^per_page,
      offset: (^page - 1) * ^per_page
    )
    |> Repo.all()
  end

  def count_by_podcast_id(podcast_id) do
    from(e in Episode, where: e.podcast_id == ^podcast_id)
    |> Repo.aggregate(:count)
  end

  def get_by_id_for_episode_show(id) do
    Repo.get!(Episode, id)
    |> Repo.preload([
      :enclosures,
      podcast: :feeds,
      gigs: :persona,
      recommendations: :user,
      chapters: [recommendations: :user]
    ])
  end

  def get_by_id_for_episode_player(id) do
    Repo.get!(Episode, id)
    |> Repo.preload([
      :enclosures,
      podcast: :feeds,
      gigs: :persona,
      chapters: [recommendations: :user]
    ])
  end

  def get_by_id(id) do
    Repo.get!(Episode, id)
  end

  def ids_by_category_id_and_podcast_id(category_id, podcast_id) do
    from(c in Category,
      join: p in assoc(c, :podcasts),
      join: e in assoc(p, :episodes),
      where: c.id == ^category_id and (not p.blocked or is_nil(p.blocked)) and p.id == ^podcast_id,
      select: e.id
    )
    |> Repo.all()
  end
end
