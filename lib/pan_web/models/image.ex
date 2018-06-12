defmodule PanWeb.Image do
  use Pan.Web, :model

  schema "images" do
    field :filename, :string
    field :content_type, :string
    field :path, :string
    belongs_to :podcast, PanWeb.Podcast
    belongs_to :episode, PanWeb.Episode
    belongs_to :persona, PanWeb.Persona

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:filename, :content_type, :path, :podcast_id, :episode_id, :persona_id])
    |> validate_required([:filename, :path])
  end
end
