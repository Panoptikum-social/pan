defmodule Pan.Like do
  use Pan.Web, :model

  schema "likes" do
    field :comment, :string
    belongs_to :enjoyer, Pan.Enjoyer
    belongs_to :podcast, Pan.Podcast
    belongs_to :episode, Pan.Episode
    belongs_to :chapter, Pan.Chapter
    belongs_to :user, Pan.User
    belongs_to :category, Pan.Category
    belongs_to :recommend_to, Pan.RecommendTo

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
