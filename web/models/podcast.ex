defmodule Pan.Podcast do
  use Pan.Web, :model

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

    has_many :episodes, Pan.Episode
    has_many :feeds, Pan.Feed
    many_to_many :categories, Pan.Category, join_through: "categories_podcasts"
    many_to_many :contributors, Pan.Contributor, join_through: "contributors_podcasts"
    many_to_many :listeners, Pan.User, join_through: "subscriptions"
    many_to_many :followers, Pan.User, join_through: "followers_podcasts"
    many_to_many :languages, Pan.Language, join_through: "languages_podcasts"
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
    |> unique_constraint(:website)
  end
end
