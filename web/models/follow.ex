defmodule Pan.Follow do
  use Pan.Web, :model

  @optional_fields ~w(user_id persona_id)

  schema "follows" do
    belongs_to :follower, Pan.User
    belongs_to :podcast, Pan.Podcast
    belongs_to :user, Pan.User
    belongs_to :persona, Pan.Persona
    belongs_to :category, Pan.Category

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [], @optional_fields)
    |> validate_required([])
  end
end
