defmodule Pan.Episode do
  use Pan.Web, :model

  schema "episodes" do
    field :title, :string
    field :link, :string
    field :publishing_date, Ecto.DateTime
    field :guid, :string
    field :description, :string
    field :shownotes, :string
    field :payment_link_title, :string
    field :payment_link_url, :string
    field :deep_link, :string
    field :duration, :string
    field :author, :string
    field :subtitle, :string
    field :summary, :string
    timestamps

    belongs_to :podcast, Pan.Podcast

    has_many :chapters, Pan.Chapter, on_delete: :delete_all
    has_many :enclosures, Pan.Enclosure, on_delete: :delete_all
    many_to_many :contributors, Pan.Contributor, join_through: "contributors_episodes", on_delete: :delete_all
  end

  @required_fields ~w(title link publishing_date description
                      shownotes duration author)
  @optional_fields ~w(payment_link_title payment_link_url deep_link subtitle summary guid)

  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(model, params \\ %{}) do
    model
    |> cast(params, @required_fields, @optional_fields)
    |> unique_constraint(:guid)
  end
end
