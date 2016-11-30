defmodule Pan.Podcast do
  use Pan.Web, :model
  alias Pan.Repo
  alias Pan.Like
  alias Pan.Follow
  alias Pan.Subscription

  schema "podcasts" do
    field :title, :string
    field :website, :string
    field :description, :string
    field :summary, :string
    field :image_title, :string
    field :image_url, :string
    field :last_build_date, Ecto.DateTime
    field :payment_link_title, :string
    field :payment_link_url, :string
    field :author, :string
    field :explicit, :boolean, default: false
    field :unique_identifier, Ecto.UUID
    timestamps

    belongs_to :owner, Pan.User

    has_many :episodes, Pan.Episode, on_delete: :delete_all
    has_many :feeds, Pan.Feed, on_delete: :delete_all
    has_many :subscriptions, Pan.Subscription
    many_to_many :categories, Pan.Category, join_through: "categories_podcasts", on_delete: :delete_all
    many_to_many :contributors, Pan.Contributor, join_through: "contributors_podcasts", on_delete: :delete_all
    many_to_many :listeners, Pan.User, join_through: "subscriptions", on_delete: :delete_all
    many_to_many :followers, Pan.User, join_through: "likes", join_keys: [podcast_id: :id, enjoyer_id: :id]
    many_to_many :languages, Pan.Language, join_through: "languages_podcasts", on_delete: :delete_all
  end


  @required_fields ~w(title website description summary image_title image_url
                      last_build_date payment_link_title payment_link_url author explicit
                      unique_identifier)
  @optional_fields ~w()

  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(model, params \\ %{}) do
    model
    |> cast(params, @required_fields, @optional_fields)
    |> unique_constraint(:title)
  end


  def like(podcast_id, user_id) do
    case Like.find_podcast_like(user_id, podcast_id) do
      nil ->
        %Like{enjoyer_id: user_id, podcast_id: podcast_id}
        |> Repo.insert
      like ->
        Repo.delete!(like)
    end
  end


  def follow(podcast_id, user_id) do
    case Repo.get_by(Follow, follower_id: user_id,
                             podcast_id: podcast_id) do
      nil ->
        %Follow{follower_id: user_id, podcast_id: podcast_id}
        |> Repo.insert
      like ->
        Repo.delete!(like)
    end
  end


  def subscribe(podcast_id, user_id) do
    case Repo.get_by(Subscription, user_id: user_id,
                             podcast_id: podcast_id) do
      nil ->
        %Subscription{user_id: user_id, podcast_id: podcast_id}
        |> Repo.insert
      like ->
        Repo.delete!(like)
    end
  end


  def follower_mailboxes(podcast_id) do
    Repo.all(from l in Follow, where: l.podcast_id == ^podcast_id,
                               select: [:follower_id])
    |> Enum.map(fn(user) ->  "mailboxes:" <> Integer.to_string(user.follower_id) end)
  end


  def likes(id) do
    from(l in Like, where: l.podcast_id == ^id)
    |> Repo.aggregate(:count, :id)
    |> Integer.to_string
  end

  def follows(id) do
    from(f in Follow, where: f.podcast_id == ^id)
    |> Repo.aggregate(:count, :id)
    |> Integer.to_string
  end

  def subscriptions(id) do
    from(s in Subscription, where: s.podcast_id == ^id)
    |> Repo.aggregate(:count, :id)
    |> Integer.to_string
  end
end