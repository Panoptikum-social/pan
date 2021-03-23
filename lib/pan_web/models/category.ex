defmodule PanWeb.Category do
  use PanWeb, :model
  alias Pan.Repo
  alias PanWeb.{Category, Follow, Like, Language}

  schema "categories" do
    field(:title, :string)
    field(:elastic, :boolean)

    has_many(:children, PanWeb.Category, foreign_key: :parent_id)

    belongs_to(:parent, PanWeb.Category)

    many_to_many(:podcasts, PanWeb.Podcast,
      join_through: "categories_podcasts",
      on_replace: :delete
    )

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:title, :parent_id, :elastic])
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

  def update_search_index(id) do
    category = Repo.get(Category, id)

    put(
      "/panoptikum_" <>
        Application.get_env(:pan, :environment) <>
        "/categories/" <> Integer.to_string(id),
      title: category.title,
      url: category_frontend_path(PanWeb.Endpoint, :show, id)
    )
  end

  def delete_search_index(id) do
    delete(
      "http://127.0.0.1:9200/panoptikum_" <>
        Application.get_env(:pan, :environment) <>
        "/categories/" <> Integer.to_string(id)
    )
  end

  def delete_search_index_orphans() do
    category_ids =
      from(c in Category, select: c.id)
      |> Repo.all()

    max_category_id = Enum.max(category_ids)

    all_ids =
      Range.new(1, max_category_id)
      |> Enum.to_list()

    deleted_ids = all_ids -- category_ids

    for deleted_id <- deleted_ids, do: delete_search_index(deleted_id)
  end

  def tree do
    from(c in Category,
      order_by: :title,
      join: subcategories in assoc(c, :children),
      order_by: subcategories.title,
      preload: [children: subcategories],
      where: is_nil(c.parent_id),
      select: [:id, :title, children: [:id, :title]]
    )
    |> Repo.all()
  end

  def stats_tree do
    from(c in Category,
      order_by: :title,
      join: subcategories in assoc(c, :children),
      order_by: subcategories.title,
      where: is_nil(c.parent_id),
      preload: [children: subcategories],
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
end
