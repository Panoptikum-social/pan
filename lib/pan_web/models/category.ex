defmodule PanWeb.Category do
  use PanWeb, :model
  alias Pan.{Repo, Search}
  alias PanWeb.{Follow, Like, Category, Community}

  schema "categories" do
    field(:title, :string)
    field(:full_text, :boolean, default: false)

    has_many(:children, PanWeb.Category, foreign_key: :parent_id, preload_order: [asc: :title])
    has_one(:community, Community)

    belongs_to(:parent, PanWeb.Category)

    many_to_many(:podcasts, PanWeb.Podcast,
      join_through: "categories_podcasts",
      on_replace: :delete
    )

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:title, :parent_id, :full_text])
    |> validate_required([:title])
  end

  def like(category_id, user_id) do
    like =
      Repo.get_by(Like,
        enjoyer_id: user_id,
        category_id: category_id
      )

    case like do
      nil ->
        %Like{enjoyer_id: user_id, category_id: category_id}
        |> Repo.insert()

      like ->
        {:ok, Repo.delete!(like)}
    end
  end

  def follow(category_id, user_id) do
    follow =
      Repo.get_by(Follow,
        follower_id: user_id,
        category_id: category_id
      )

    case follow do
      nil ->
        %Follow{follower_id: user_id, category_id: category_id}
        |> Repo.insert()

      follow ->
        {:ok, Repo.delete!(follow)}
    end
  end

  def follower_mailboxes(category_id) do
    from(l in Follow,
      where: l.category_id == ^category_id,
      select: [:follower_id]
    )
    |> Repo.all()
    |> Enum.map(fn user -> "mailboxes:" <> Integer.to_string(user.follower_id) end)
  end

  def likes(id) do
    from(l in Like, where: l.category_id == ^id)
    |> Repo.aggregate(:count)
    |> Integer.to_string()
  end

  def follows(id) do
    from(l in Follow, where: l.category_id == ^id)
    |> Repo.aggregate(:count)
    |> Integer.to_string()
  end

  def tree do
    from(c in Category,
      order_by: :title,
      preload: [children: :children],
      where: is_nil(c.parent_id),
      select: [:id, :title, children: [:id, :title]]
    )
    |> Repo.all()
  end

  # Public category list only — communities get their own dedicated
  # /communities section now, so their categories (and any parent left with no
  # remaining children once its community-only children are hidden) don't show
  # up here. Other consumers of tree/0 (e.g. the admin category merge tool)
  # still need to see every category, so this is a separate function rather
  # than a filter inside tree/0 itself.
  def public_tree do
    community_category_ids =
      from(c in Community, select: c.category_id)
      |> Repo.all()
      |> MapSet.new()

    tree()
    |> Enum.reject(&MapSet.member?(community_category_ids, &1.id))
    |> Enum.flat_map(fn category ->
      had_children = category.children != []

      visible_children =
        Enum.reject(category.children, &MapSet.member?(community_category_ids, &1.id))

      if had_children and visible_children == [] do
        []
      else
        [%{category | children: visible_children}]
      end
    end)
  end

  def stats_tree do
    from(c in Category,
      order_by: :title,
      where: is_nil(c.parent_id),
      preload: [children: :children],
      preload: [:podcasts, children: :podcasts],
      select: [:id, :title, podcasts: :id, children: [:id, :title, podcasts: :id]]
    )
    |> Repo.all()
  end

  def by_id_exists?(id) do
    from(Category,
      where: [id: ^id],
      select: [:id]
    )
    |> Repo.one()
    |> is_nil()
    |> Kernel.not()
  end

  def has_community?(id) do
    from(Community,
      where: [category_id: ^id],
      select: [:id]
    )
    |> Repo.one()
    |> is_nil()
    |> Kernel.not()
  end

  def get_with_children_and_parent(id) do
    from(c in Category,
      where: [id: ^id],
      left_join: children in assoc(c, :children),
      left_join: p in assoc(c, :parent),
      order_by: children.title,
      preload: [parent: p, children: children],
      select: [:id, :title, children: [:id, :title], parent: [:id, :title]]
    )
    |> Repo.one()
  end

  def get_by_id(id) do
    Repo.get!(Category, id)
  end

  def get_by_id_with_parent(id) do
    Category
    |> Repo.get!(id)
    |> Repo.preload(:parent)
  end

  @doc """
  The other categories with the same title as category `id` (case and
  surrounding spaces ignored), as `{id, podcast count}`, most podcasts first.
  """
  def same_title_candidates(id) do
    from(c in Category,
      join: s in Category,
      on: fragment("lower(trim(?))", s.title) == fragment("lower(trim(?))", c.title),
      left_join: cp in "categories_podcasts",
      on: cp.category_id == c.id,
      where: s.id == ^id and c.id != ^id,
      group_by: c.id,
      select: {c.id, count(cp.podcast_id)},
      order_by: [desc: count(cp.podcast_id), asc: c.id]
    )
    |> Repo.all()
  end

  @doc """
  All categories sharing their title with another one (case and surrounding
  spaces ignored), as `{id, best?}`, best being the one with the most
  podcasts of its title (the lower id on a tie).
  """
  def namesakes do
    Repo.query!("""
    SELECT id, rank = 1 FROM (
      SELECT c.id,
        count(*) OVER (PARTITION BY lower(trim(c.title))) AS namesakes,
        row_number() OVER (
          PARTITION BY lower(trim(c.title))
          ORDER BY (SELECT count(*) FROM categories_podcasts cp WHERE cp.category_id = c.id) DESC, c.id
        ) AS rank
      FROM categories c
    ) ranked
    WHERE namesakes > 1
    """).rows
    |> Enum.map(fn [id, best?] -> {id, best?} end)
  end

  @doc "Category id => number of podcasts directly in it (not in subcategories)."
  def podcast_counts do
    from(cp in "categories_podcasts",
      group_by: cp.category_id,
      select: {cp.category_id, count(cp.podcast_id)}
    )
    |> Repo.all()
    |> Map.new()
  end

  @doc "Ids of categories whose title has no letter (blank, \"0\"), to be merged by hand."
  def no_title_ids do
    from(c in Category, where: fragment("? !~ '[[:alpha:]]'", c.title), select: c.id)
    |> Repo.all()
    |> MapSet.new()
  end

  @doc "Ids of categories with nothing attached, safe to delete."
  def empty_ids do
    from(c in empty_query(), select: c.id)
    |> Repo.all()
    |> MapSet.new()
  end

  def delete_empty(id) do
    case Repo.one(from(c in empty_query(), where: c.id == ^id)) do
      nil ->
        {:error,
         "Only categories without podcasts, subcategories, follows, likes and community can be deleted."}

      category ->
        Repo.delete!(category)
        Search.Category.delete_index(id)
        :ok
    end
  end

  # no podcasts, subcategories, follows, likes or community
  defp empty_query do
    from(c in Category,
      as: :category,
      where:
        not exists(
          from(cp in "categories_podcasts",
            where: cp.category_id == parent_as(:category).id,
            select: 1
          )
        ) and
          not exists(
            from(ch in Category, where: ch.parent_id == parent_as(:category).id, select: 1)
          ) and
          not exists(
            from(f in Follow, where: f.category_id == parent_as(:category).id, select: 1)
          ) and
          not exists(from(l in Like, where: l.category_id == parent_as(:category).id, select: 1)) and
          not exists(
            from(co in Community, where: co.category_id == parent_as(:category).id, select: 1)
          )
    )
  end

  # The tree shows three levels (see tree/0), so a move must not go deeper.
  @max_depth 3

  @doc """
  Makes category `id` (with its subcategories) a subcategory of `parent_id`.
  Search docs only carry category ids and titles, so nothing is re-indexed.
  """
  def move_into(id, id), do: {:error, "A category can't be moved into itself."}

  def move_into(id, parent_id) do
    category = Repo.get!(Category, id)
    ancestor_ids = ancestor_ids(parent_id)

    cond do
      category.parent_id == parent_id ->
        {:error, "The category is already a subcategory there."}

      id in ancestor_ids ->
        {:error, "A category can't be moved into one of its own subcategories."}

      length(ancestor_ids) + height(id) > @max_depth ->
        {:error, "That would make the tree deeper than #{@max_depth} levels."}

      has_child_titled?(parent_id, category.title) ->
        {:error, "The target has a subcategory with that title already, merge instead."}

      true ->
        category |> Ecto.Changeset.change(parent_id: parent_id) |> Repo.update!()
        :ok
    end
  end

  # [id, its parent's id, ...] up to the top level
  defp ancestor_ids(nil), do: []

  defp ancestor_ids(id),
    do: [
      id | ancestor_ids(Repo.one!(from(c in Category, where: c.id == ^id, select: c.parent_id)))
    ]

  # levels of the subtree below and including category `id`
  defp height(id) do
    from(c in Category, where: c.parent_id == ^id, select: c.id)
    |> Repo.all()
    |> Enum.map(&height/1)
    |> Enum.max(fn -> 0 end)
    |> Kernel.+(1)
  end

  defp has_child_titled?(parent_id, title) do
    from(c in Category,
      where:
        c.parent_id == ^parent_id and
          fragment("lower(trim(?))", c.title) == ^String.downcase(String.trim(title))
    )
    |> Repo.exists?()
  end

  def merge(id, id), do: {:error, "A category can't be merged into itself."}

  # A community is unique per category and carries moderators, curators,
  # curations and followers, so two of them can't be merged automatically.
  def merge(from_id, to_id) do
    if Community.get_by_category_id(from_id) && Community.get_by_category_id(to_id) do
      {:error, "Both categories have a community, merge the communities first."}
    else
      moved_podcast_ids = Search.Category.podcast_ids(from_id)

      from(f in Follow, where: f.category_id == ^from_id)
      |> Repo.update_all(set: [category_id: to_id])

      from(l in Like, where: l.category_id == ^from_id)
      |> Repo.update_all(set: [category_id: to_id])

      already_in_to_ids =
        from(r in "categories_podcasts",
          where: r.category_id == ^to_id,
          select: [r.podcast_id]
        )
        |> Repo.all()

      from(r in "categories_podcasts",
        where:
          r.category_id == ^from_id and
            r.podcast_id not in ^already_in_to_ids
      )
      |> Repo.update_all(set: [category_id: to_id])

      from(r in "categories_podcasts",
        where:
          r.category_id == ^from_id and
            r.podcast_id in ^already_in_to_ids
      )
      |> Repo.delete_all()

      from(c in Category, where: c.parent_id == ^from_id)
      |> Repo.update_all(set: [parent_id: to_id])

      from(c in Community, where: c.category_id == ^from_id)
      |> Repo.update_all(set: [category_id: to_id])

      Repo.get!(Category, from_id)
      |> Repo.delete!()

      Search.Category.delete_index(from_id)
      Search.Category.update_index(to_id)

      # their docs still list the deleted category
      Search.Category.reset_podcasts(moved_podcast_ids)
      :ok
    end
  end
end
