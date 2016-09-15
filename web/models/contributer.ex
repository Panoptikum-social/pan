defmodule Pan.Contributer do
  use Pan.Web, :model

  schema "contributers" do
    field :name, :string
    field :uri, :string
    belongs_to :user, Pan.User
    many_to_many :episodes, Pan.Episode, join_through: "contributers_episodes"
    many_to_many :podcasts, Pan.Podcast, join_through: "contributers_podcasts"

    timestamps
  end

  @required_fields ~w(name uri)
  @optional_fields ~w()

  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
  end
end
