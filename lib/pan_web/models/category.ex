defmodule PanWeb.Category do
  use Pan.Web, :model
  alias Pan.Repo
  alias PanWeb.{Follow, Like}

  schema "categories" do
    field(:title, :string)
    field(:full_text, :boolean)

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
end
