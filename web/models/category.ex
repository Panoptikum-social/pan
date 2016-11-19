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

    timestamps
  end

  @required_fields ~w(title)
  @optional_fields ~w()

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
end