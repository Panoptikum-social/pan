defmodule Pan.Category do
  use Pan.Web, :model
  alias Pan.Repo
  alias Pan.Like
  alias Pan.Follow

  schema "categories" do
    field :title, :string

    has_many :children, Pan.Category, foreign_key: :parent_id

    belongs_to :parent, Pan.Category
    many_to_many :podcasts, Pan.Podcast, join_through: "categories_podcasts",
                                         on_replace: :delete

    timestamps()
  end

  @required_fields ~w(title)
  @optional_fields ~w(parent_id)

  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(model, params \\ %{}) do
    model
    |> cast(params, @required_fields, @optional_fields)
  end


  def like(category_id, user_id) do
    case Repo.get_by(Like, enjoyer_id: user_id,
                           category_id: category_id) do
      nil ->
        %Like{enjoyer_id: user_id, category_id: category_id}
        |> Repo.insert
      like ->
        Repo.delete!(like)
    end
  end


  def follow(category_id, user_id) do
    case Repo.get_by(Follow, follower_id: user_id,
                             category_id: category_id) do
      nil ->
        %Follow{follower_id: user_id, category_id: category_id}
        |> Repo.insert
      like ->
        Repo.delete!(like)
    end
  end


  def follower_mailboxes(category_id) do
    Repo.all(from l in Follow, where: l.category_id == ^category_id,
                               select: [:follower_id])
    |> Enum.map(fn(user) ->  "mailboxes:" <> Integer.to_string(user.follower_id) end)
  end


  def likes(id) do
    from(l in Like, where: l.category_id == ^id)
    |> Repo.aggregate(:count, :id)
    |> Integer.to_string
  end


  def follows(id) do
    from(l in Follow, where: l.category_id == ^id)
    |> Repo.aggregate(:count, :id)
    |> Integer.to_string
  end
end