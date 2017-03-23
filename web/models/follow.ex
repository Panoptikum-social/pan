defmodule Pan.Follow do
  use Pan.Web, :model

  schema "follows" do
    belongs_to :follower, Pan.User
    belongs_to :podcast, Pan.Podcast
    belongs_to :user, Pan.User
    belongs_to :persona, Pan.Persona
    belongs_to :category, Pan.Category

    timestamps()
  end


  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:user_id, :persona_id, :follower_id, :podcast_id, :category_id])
    |> validate_required([:follower_id])
  end
end
