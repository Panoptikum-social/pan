defmodule PanWeb.Community do
  use PanWeb, :model
  alias Pan.Repo
  alias PanWeb.{Category, Community, Follow, User}

  schema "communities" do
    field(:title, :string)
    field(:website, :string)
    field(:description, Ecto.EctoText)
    field(:fediverse_address, :string)

    belongs_to(:category, Category)

    many_to_many(:moderators, User, join_through: "moderations")
    has_many(:personas, through: [:category, :podcasts, :contributors])

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:title, :website, :description, :fediverse_address, :category_id])
    |> validate_required([:title, :category_id])
    |> validate_length(:title, max: 255)
    |> validate_length(:website, max: 255)
    |> validate_length(:fediverse_address, max: 255)
    |> unique_constraint(:category_id)
  end

  def follow(community_id, user_id) do
    follow =
      Repo.get_by(Follow,
        follower_id: user_id,
        community_id: community_id
      )

    case follow do
      nil ->
        %Follow{follower_id: user_id, community_id: community_id}
        |> Repo.insert()

      follow ->
        {:ok, Repo.delete!(follow)}
    end
  end

  def follows(id) do
    from(f in Follow, where: f.community_id == ^id)
    |> Repo.aggregate(:count)
    |> Integer.to_string()
  end

  def get_by_id(id) do
    Repo.get!(Community, id)
  end

  def find_by_id(id) do
    Repo.get(Community, id)
    |> Repo.preload(moderators: from(u in User, order_by: u.name))
  end

  def all do
    from(c in Community, order_by: c.title)
    |> Repo.all()
  end

  def get_by_category_id(category_id) do
    Repo.get_by(Community, category_id: category_id)
    |> Repo.preload(:moderators)
  end

  def personas(id) do
    from(p in (Community |> Repo.get!(id) |> Ecto.assoc(:personas)), order_by: p.name)
    |> Repo.all()
  end
end
