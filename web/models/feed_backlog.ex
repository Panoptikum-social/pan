defmodule Pan.FeedBacklog do
  use Pan.Web, :model

  @required_fields ~w(url in_progress)
  @optional_fields ~w(feed_generator)

  schema "backlog_feeds" do
    field :url, :string
    field :feed_generator, :string
    field :in_progress, :boolean, default: false
    belongs_to :user, Pan.User

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
  end
end
