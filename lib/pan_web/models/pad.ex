defmodule PanWeb.Pad do
  use PanWeb, :model
  alias Pan.Repo
  alias PanWeb.{Follow, Moderation, Pad, PadSnapshot}

  # Markdown edited together by the followers of one community. The title is
  # unique within the community; the slug made from it is the pad's address
  # and changes along with the title.
  schema "pads" do
    field(:title, :string)
    field(:slug, :string)
    field(:read_only, :boolean, default: false)
    field(:yjs_state, :binary)
    field(:markdown, Ecto.EctoText, default: "")

    belongs_to(:community, PanWeb.Community)
    has_many(:snapshots, PadSnapshot)

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:title])
    |> update_change(:title, &String.trim/1)
    |> validate_required([:title])
    |> validate_length(:title, max: 255)
    |> put_slug()
    |> unique_constraint(:title,
      name: :pads_community_id_slug_index,
      message: "a pad with this or a very similar title already exists"
    )
  end

  def read_only_changeset(struct, read_only) do
    change(struct, read_only: read_only)
  end

  defp put_slug(changeset) do
    case get_change(changeset, :title) do
      nil ->
        changeset

      title ->
        case slugify(title) do
          "" -> add_error(changeset, :title, "needs at least one letter or digit")
          slug -> put_change(changeset, :slug, slug)
        end
    end
  end

  @doc """
  Lower case letters and digits joined by dashes: German umlauts and ß are
  spelled out, other accents dropped, letters of non-Latin scripts kept.

      iex> PanWeb.Pad.slugify("  Grüße an die Ärzte! (2026) ")
      "gruesse-an-die-aerzte-2026"
  """
  def slugify(title) do
    title
    |> String.downcase()
    |> String.replace(["ä", "ö", "ü", "ß"], fn
      "ä" -> "ae"
      "ö" -> "oe"
      "ü" -> "ue"
      "ß" -> "ss"
    end)
    |> String.normalize(:nfd)
    |> String.replace(~r/\p{Mn}/u, "")
    |> String.replace(~r/[^\p{L}\p{N}]+/u, "-")
    |> String.trim("-")
  end

  @doc """
  What a user may do with the pads of a community: `read` (and edit) as a
  follower, `manage` (create, rename, delete, toggle read only) as a follower
  who also moderates it. Moderating alone gives nothing.
  """
  def permissions(nil, _community_id), do: %{read: false, manage: false}

  def permissions(user_id, community_id) do
    if Follow.find_community_follow(user_id, community_id) do
      moderator =
        from(m in Moderation, where: m.user_id == ^user_id and m.community_id == ^community_id)
        |> Repo.exists?()

      %{read: true, manage: moderator}
    else
      %{read: false, manage: false}
    end
  end

  def all_of_community(community_id) do
    from(p in Pad, where: p.community_id == ^community_id, order_by: p.title)
    |> Repo.all()
  end

  def get_by_slug(community_id, slug) do
    Repo.get_by(Pad, community_id: community_id, slug: slug)
  end

  def create(community_id, params) do
    %Pad{community_id: community_id}
    |> changeset(params)
    |> Repo.insert()
  end
end
