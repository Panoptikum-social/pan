defmodule PanWeb.Curation do
  use PanWeb, :model
  alias Pan.Repo
  alias PanWeb.{CategoryPodcast, Community, Curation, Curatorship, Moderation, User}

  @grades [:recommended, :rather_recommended, :indifferent, :rather_declined, :declined]

  # A curator's assessment of a podcast within one community, meant for third
  # party platforms. Readable only by that community's curators and moderators
  # and by admins, never by the public or the podcasters.
  schema "curations" do
    field(:grade, Ecto.Enum, values: @grades)
    field(:text, Ecto.EctoText)

    belongs_to(:user, PanWeb.User)
    belongs_to(:podcast, PanWeb.Podcast)
    belongs_to(:community, PanWeb.Community)

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:grade, :text])
    |> validate_required([:grade])
    |> unique_constraint([:user_id, :podcast_id, :community_id])
  end

  def grades, do: @grades

  def grade_label(grade), do: grade |> to_string() |> String.replace("_", " ")

  @doc """
  What a user may do with the curations of a community: `curate` (write their
  own) as an assigned curator, `manage` (toggle open_for_curation) as one of its
  moderators or an admin, `read` if either applies. Users who are neither
  curator, moderator nor admin get nothing, even with curatorships left over.
  """
  def permissions(user_id, community_id) do
    user = Repo.get!(User, user_id)

    if user.curator || user.moderator || user.admin do
      curate =
        from(c in Curatorship, where: c.user_id == ^user_id and c.community_id == ^community_id)
        |> Repo.exists?()

      manage =
        user.admin ||
          from(m in Moderation, where: m.user_id == ^user_id and m.community_id == ^community_id)
          |> Repo.exists?()

      %{curate: curate, manage: manage, read: curate || manage}
    else
      %{curate: false, manage: false, read: false}
    end
  end

  @doc "The communities whose curations the user can see: all of them for admins."
  def communities_for(user_id) do
    if Repo.get!(User, user_id).admin do
      Community.all()
    else
      curated = from(c in Curatorship, where: c.user_id == ^user_id, select: c.community_id)
      moderated = from(m in Moderation, where: m.user_id == ^user_id, select: m.community_id)

      from(c in Community,
        where: c.id in subquery(curated) or c.id in subquery(moderated),
        order_by: c.title
      )
      |> Repo.all()
    end
  end

  @doc """
  The podcasts of a community with their grade counts and whether `user_id`
  has curated them. `filter` is `:open`, `:done` or `:all`, `search` a text
  the title has to contain.
  """
  def overview(%Community{} = community, user_id, filter, search) do
    from(cp in CategoryPodcast,
      join: p in assoc(cp, :podcast),
      left_join: c in Curation,
      on: c.podcast_id == cp.podcast_id and c.community_id == ^community.id,
      where: cp.category_id == ^community.category_id,
      group_by: [p.id, p.title, cp.open_for_curation],
      order_by: p.title,
      select: %{
        id: p.id,
        title: p.title,
        open: cp.open_for_curation,
        grades: fragment("array_remove(array_agg(?), NULL)", c.grade),
        mine: fragment("coalesce(bool_or(? = ?), false)", c.user_id, ^user_id)
      }
    )
    |> filter_open(filter)
    |> search_title(String.trim(search))
    |> Repo.all()
    |> Enum.map(&%{&1 | grades: Enum.frequencies(&1.grades)})
  end

  defp filter_open(query, :open), do: from([cp] in query, where: cp.open_for_curation)
  defp filter_open(query, :done), do: from([cp] in query, where: not cp.open_for_curation)
  defp filter_open(query, :all), do: query

  defp search_title(query, ""), do: query

  defp search_title(query, search),
    do: from([_cp, p] in query, where: ilike(p.title, ^"%#{search}%"))

  @doc "The podcast's link to the community, nil if it is not part of it (any more)."
  def category_podcast(%Community{category_id: category_id}, podcast_id) do
    Repo.get_by(CategoryPodcast, category_id: category_id, podcast_id: podcast_id)
  end

  def set_open(%Community{category_id: category_id}, podcast_id, open) do
    from(cp in CategoryPodcast,
      where: cp.category_id == ^category_id and cp.podcast_id == ^podcast_id
    )
    |> Repo.update_all(set: [open_for_curation: open])
  end

  def for_podcast(community_id, podcast_id) do
    from(c in Curation,
      where: c.community_id == ^community_id and c.podcast_id == ^podcast_id,
      order_by: [desc: c.updated_at],
      preload: :user
    )
    |> Repo.all()
  end

  @doc "The user's curation of the podcast in the community, a new one if there is none yet."
  def mine(community_id, podcast_id, user_id) do
    Repo.get_by(Curation, community_id: community_id, podcast_id: podcast_id, user_id: user_id) ||
      %Curation{community_id: community_id, podcast_id: podcast_id, user_id: user_id}
  end

  def save(%Curation{} = curation, params) do
    curation
    |> changeset(params)
    |> Repo.insert_or_update()
  end
end
