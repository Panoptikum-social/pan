defmodule PanWeb.AlternateFeed do
  use PanWeb, :model

  schema "alternate_feeds" do
    field(:title, :string)
    field(:url, :string)
    belongs_to(:feed, PanWeb.Feed)

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:title, :url])
    |> validate_required([:url])
  end
end
