defmodule PanWeb.Follow do
  use Pan.Web, :model

  schema "follows" do
    belongs_to :follower, PanWeb.User
    belongs_to :podcast, PanWeb.Podcast
    belongs_to :user, PanWeb.User
    belongs_to :persona, PanWeb.Persona
    belongs_to :category, PanWeb.Category

    timestamps()
  end


  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:user_id, :persona_id, :follower_id, :podcast_id, :category_id])
    |> validate_required([:follower_id])
  end
end
