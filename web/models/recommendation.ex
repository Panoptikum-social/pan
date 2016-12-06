defmodule Pan.Recommendation do
  use Pan.Web, :model

  schema "recommendations" do
    field :comment, :string
    belongs_to :user, Pan.User
    belongs_to :podcast, Pan.Podcast
    belongs_to :episode, Pan.Episode
    belongs_to :chapter, Pan.Chapter

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:comment])
    |> validate_required([:comment])
  end
end
