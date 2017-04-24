defmodule Pan.Episode do
  use Pan.Web, :model
  alias Pan.Repo
  alias Pan.Like
  alias Pan.Episode
  alias Pan.Gig

  schema "episodes" do
    field :title, :string
    field :link, :string
    field :publishing_date, :naive_datetime
    field :guid, :string
    field :description, :string
    field :shownotes, :string
    field :payment_link_title, :string
    field :payment_link_url, :string
    field :deep_link, :string
    field :duration, :string
    field :subtitle, :string
    field :summary, :string
    timestamps()

    belongs_to :podcast, Pan.Podcast

    has_many :chapters, Pan.Chapter, on_delete: :delete_all
    has_many :enclosures, Pan.Enclosure, on_delete: :delete_all
    has_many :recommendations, Pan.Recommendation, on_delete: :delete_all

    has_many :gigs, Pan.Gig
    many_to_many :contributors, Pan.Persona, join_through: "gigs", on_delete: :delete_all
  end


  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:title, :link, :publishing_date, :description, :shownotes, :duration,
                     :payment_link_title, :payment_link_url, :deep_link, :subtitle, :summary,
                     :guid, :podcast_id])
    |> validate_required([:title, :link, :publishing_date, :podcast_id])
    |> unique_constraint(:guid)
  end


  def like(episode_id, user_id) do
    case Repo.get_by(Like, enjoyer_id: user_id,
                           episode_id: episode_id) do
      nil ->
        episode = Repo.get(Episode, episode_id)
        %Like{enjoyer_id: user_id, episode_id: episode_id,
              podcast_id: episode.podcast_id}
        |> Repo.insert
      like ->
        Repo.delete!(like)
    end
  end

  def likes(id) do
    from(l in Like, where: l.episode_id == ^id)
    |> Repo.aggregate(:count, :id)
    |> Integer.to_string
  end


  def latest do
    from(e in Pan.Episode, order_by: [desc: :publishing_date],
                           join: p in assoc(e, :podcast),
                           where: (is_nil(p.blocked) or p.blocked == false) and
                                  e.publishing_date < ^NaiveDateTime.utc_now(),
                           preload: :podcast,
                           limit: 5)
    |> Repo.all()
  end


  def author(episode) do
    gig = from(Gig, where: [role: "author",
                            episode_id: ^episode.id],
                    preload: :persona)
    |> Repo.one()

    if gig, do: gig.persona
  end


  def update_search_index(id) do
    episode = Repo.get(Episode, id)
              |> Repo.preload(:podcast)
    unless episode.podcast.blocked == true do
      put("/panoptikum_" <> Application.get_env(:pan, :environment) <> "/episodes/" <> Integer.to_string(id),
          [title:       episode.title,
           subtitle:    episode.subtitle,
           description: episode.description,
           summary:     episode.summary,
           shownotes:   episode.shownotes,
           url:         episode_frontend_path(Pan.Endpoint, :show, id)])
    end
  end


  def delete_search_index_orphans() do
    episode_ids = (from c in Episode, select: c.id)
                  |> Repo.all()

    max_episode_id = Enum.max(episode_ids)
    all_ids = Range.new(1, max_episode_id) |> Enum.to_list()
    deleted_ids = all_ids -- episode_ids

    for deleted_id <- deleted_ids do
      delete("http://127.0.0.1:9200/panoptikum_" <> Application.get_env(:pan, :environment) <>
             "/episodes/" <> Integer.to_string(deleted_id))
    end
  end
end
