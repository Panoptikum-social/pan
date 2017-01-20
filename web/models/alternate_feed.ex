defmodule Pan.AlternateFeed do
  use Pan.Web, :model

  schema "alternate_feeds" do
    field :title, :string
    field :url, :string
    belongs_to :feed, Pan.Feed

    timestamps()
  end

  @required_fields ~w(title url)
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
end
