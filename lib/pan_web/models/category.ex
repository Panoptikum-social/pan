defmodule PanWeb.Category do
  use PanWeb, :model
  alias Pan.{Repo, Search}
  alias PanWeb.{Follow, Like, Category, Language}

  schema "categories" do
    field(:title, :string)
    field(:full_text, :boolean)

    has_many(:children, PanWeb.Category, foreign_key: :parent_id, preload_order: [asc: :title])

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

  def get_with_children_parent_and_podcasts(id) do
    category =
      from(c in Category,
        where: [id: ^id],
        left_join: children in assoc(c, :children),
        left_join: p in assoc(c, :parent),
        order_by: children.title,
        preload: [parent: p, children: children],
        select: [:id, :title, children: [:id, :title], parent: [:id, :title]]
      )
      |> Repo.one()

    podcasts =
      from(l in Language,
        right_join: p in assoc(l, :podcasts),
        join: c in assoc(p, :categories),
        where: c.id == ^id,
        select: %{id: p.id, title: p.title, language_name: l.name, language_emoji: l.emoji}
      )
      |> Repo.all()

    %{category: category, podcasts: podcasts}
  end

  def get_by_id(id) do
    Repo.get!(Category, id)
  end

  def get_by_id_with_parent(id) do
    Category
    |> Repo.get!(id)
    |> Repo.preload(:parent)
  end

  def merge(from_id, to_id) do
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

    Pan.Search.Category.delete_index(from_id)

    Repo.get!(Category, from_id)
    |> Repo.delete!()

    Search.Category.delete_index(from_id)
    Search.Category.update_index(to_id)
  end
end
