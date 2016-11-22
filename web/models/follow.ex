defmodule Pan.Follow do
  use Pan.Web, :model

  schema "follows" do
    belongs_to :follower, Pan.User
    belongs_to :podcast, Pan.Podcast
    belongs_to :user, Pan.User
    belongs_to :category, Pan.Category

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [])
    |> validate_required([])
  end
end
