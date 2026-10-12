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
    |> cast(params, [:title, :url, :feed_id])
    |> validate_required([:url])
  end

  @doc """
  Deletes the alternate feeds with this exact URL (http and https alike)
  across all podcasts, e.g. an error page recorded as a previous URL of
  many feeds. Returns the number deleted.
  """
  def delete_by_url(url) do
    bare_url = url |> String.trim() |> String.replace(~r/^https?:\/\//i, "")

    {count, _} =
      from(a in PanWeb.AlternateFeed,
        where: fragment("regexp_replace(trim(?), '^https\\?://', '', 'i')", a.url) == ^bare_url
      )
      |> Pan.Repo.delete_all()

    count
  end
end
