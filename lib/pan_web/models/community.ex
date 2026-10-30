defmodule PanWeb.Community do
  use PanWeb, :model
  alias Pan.Repo
  alias PanWeb.{Category, Community, Follow, User}

  schema "communities" do
    field(:title, :string)
    field(:slug, :string)
    field(:website, :string)
    field(:description, Ecto.EctoText)
    field(:fediverse_address, :string)

    belongs_to(:category, Category)

    many_to_many(:moderators, User, join_through: "moderations")
    many_to_many(:curators, User, join_through: "curatorships")
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
    |> put_slug()
    |> unique_constraint(:category_id)
    |> unique_constraint(:title,
      name: :communities_slug_index,
      message: "a community with this or a very similar title already exists"
    )
  end

  # the community's address, changes along with the title (old links break,
  # by decision)
  defp put_slug(changeset) do
    case get_change(changeset, :title) do
      nil ->
        changeset

      title ->
        case PanWeb.Pad.slugify(title) do
          "" -> add_error(changeset, :title, "needs at least one letter or digit")
          slug -> put_change(changeset, :slug, slug)
        end
    end
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

  def find_by_slug(slug) do
    Repo.get_by(Community, slug: slug)
    |> Repo.preload(moderators: from(u in User, order_by: u.name))
  end

  def get_by_slug(slug), do: Repo.get_by(Community, slug: slug)
  def get_by_slug!(slug), do: Repo.get_by!(Community, slug: slug)

  @doc "Links from before #483 carry the id instead of the slug."
  def get_by_legacy_id(param) do
    case Integer.parse(param) do
      {id, ""} -> Repo.get(Community, id)
      _ -> nil
    end
  end

  def all do
    from(c in Community, order_by: c.title)
    |> Repo.all()
  end

  def get_by_category_id(category_id) do
    Repo.get_by(Community, category_id: category_id)
    |> Repo.preload(:moderators)
  end

  @doc "Titles of the communities whose category the podcast is in."
  def titles_for_podcast(podcast_id) do
    from(c in Community,
      join: cp in "categories_podcasts",
      on: cp.category_id == c.category_id,
      where: cp.podcast_id == ^podcast_id,
      order_by: c.title,
      select: c.title
    )
    |> Repo.all()
  end

  def personas(id) do
    from(p in (Community |> Repo.get!(id) |> Ecto.assoc(:personas)), order_by: p.name)
    |> Repo.all()
  end
end

defimpl Phoenix.Param, for: PanWeb.Community do
  def to_param(%{slug: slug}), do: slug
end
