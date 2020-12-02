defmodule PanWeb.Episode do
  use Pan.Web, :model
  alias Pan.Repo
  alias PanWeb.{Chapter, Enclosure, Episode, Gig, Image, Like, Persona, Podcast, Recommendation}

  schema "episodes" do
    field(:title, :string)
    field(:link, :string)
    field(:publishing_date, :naive_datetime)
    field(:guid, :string)
    field(:description, :string)
    field(:shownotes, :string)
    field(:payment_link_title, :string)
    field(:payment_link_url, :string)
    field(:deep_link, :string)
    field(:duration, :string)
    field(:subtitle, :string)
    field(:summary, :string)
    field(:image_title, :string)
    field(:image_url, :string)
    field(:elastic, :boolean)
    field(:thumbnailed, :boolean)
    timestamps()

    belongs_to(:podcast, Podcast)

    has_many(:chapters, Chapter, on_delete: :delete_all)
    has_many(:enclosures, Enclosure, on_delete: :delete_all)
    has_many(:recommendations, Recommendation, on_delete: :delete_all)
    has_many(:gigs, Gig, on_delete: :delete_all)
    has_many(:thumbnails, Image, on_delete: :delete_all)
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
      :elastic,
      :thumbnailed
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
    from(e in PanWeb.Episode,
      order_by: [fragment("? DESC NULLS LAST", e.publishing_date)],
      join: p in assoc(e, :podcast),
      where:
        not p.blocked and
          e.publishing_date < ^NaiveDateTime.utc_now(),
      preload: :podcast,
      limit: 10
    )
    |> Repo.all()
  end

  def author(episode) do
    gig =
      from(Gig,
        where: [role: "author", episode_id: ^episode.id],
        preload: :persona
      )
      |> Repo.one()

    if gig, do: gig.persona
  end

  def update_search_index(id) do
    episode =
      Repo.get(Episode, id)
      |> Repo.preload(:podcast)

    if episode.podcast.blocked == true do
      delete_search_index(id)
    else
      put(
        "/panoptikum_" <>
          Application.get_env(:pan, :environment) <>
          "/episodes/" <> Integer.to_string(id),
        title: episode.title,
        subtitle: episode.subtitle,
        description: episode.description,
        summary: episode.summary,
        shownotes: episode.shownotes,
        url: episode_frontend_path(PanWeb.Endpoint, :show, id)
      )
    end
  end

  def delete_search_index(id) do
    delete(
      "http://127.0.0.1:9200/panoptikum_" <>
        Application.get_env(:pan, :environment) <>
        "/episodes/" <> Integer.to_string(id)
    )
  end

  def delete_search_index_orphans() do
    episode_ids =
      from(e in Episode, select: e.id)
      |> Repo.all()

    max_episode_id = Enum.max(episode_ids)

    all_ids =
      Range.new(1, max_episode_id)
      |> Enum.to_list()

    for id <- all_ids do
      unless Enum.member?(episode_ids, id) do
        delete_search_index(id)
      end
    end
  end

  def cache_missing_thumbnail_images() do
    episode_ids =
      from(e in Episode,
        where: not e.thumbnailed and not is_nil(e.image_url),
        limit: 250,
        select: e.id
      )
      |> Repo.all()

    episodes =
      from(e in Episode, where: e.id in ^episode_ids)
      |> Repo.all()

    for episode <- episodes, do: Episode.cache_thumbnail_image(episode)

    from(e in Episode, where: e.id in ^episode_ids)
    |> Repo.update_all(set: [thumbnailed: true])
  end

  def cache_thumbnail_image(episode) do
    with {:error, _} <- Image.download_thumbnail("episode", episode.id, episode.image_url) do
      Episode.clear_image_url(episode)
    end
  end

  def clear_image_url(episode) do
    episode
    |> Episode.changeset(%{image_url: nil, link: episode.link || "https://example.com"})
    |> Repo.update()
  end
end
