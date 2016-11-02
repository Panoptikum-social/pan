defmodule Pan.Feed do
  use Pan.Web, :model

  schema "feeds" do
    field :self_link_title, :string
    field :self_link_url, :string
    field :next_page_url, :string
    field :prev_page_url, :string
    field :first_page_url, :string
    field :last_page_url, :string
    field :hub_link_url, :string
    field :feed_generator, :string
    timestamps

    belongs_to :podcast, Pan.Podcast
    has_many :alternate_feeds, Pan.AlternateFeed
  end

  @required_fields ~w(self_link_url )
  @optional_fields ~w(self_link_title next_page_url prev_page_url first_page_url last_page_url hub_link_url feed_generator)

  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(model, params \\ %{}) do
    model
    |> cast(params, @required_fields, @optional_fields)
  end
end
