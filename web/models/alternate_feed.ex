defmodule Pan.AlternateFeed do
  use Pan.Web, :model

  schema "alternate_feeds" do
    field :title, :string
    field :url, :string
    belongs_to :feed, Pan.Feed

    timestamps()
  end


  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:title, :url])
    |> validate_required([:url])
  end
end
