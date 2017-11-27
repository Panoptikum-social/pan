defmodule PanWeb.RssFeed do
  use Pan.Web, :model

  schema "rss_feeds" do
    field :content, :string
    belongs_to :podcast, PanWeb.Podcast

    timestamps()
  end


  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:content, :podcast_id])
    |> validate_required([:content, :podcast_id])
  end
end
