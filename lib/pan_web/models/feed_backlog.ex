defmodule PanWeb.FeedBacklog do
  use Pan.Web, :model
  alias Pan.Repo
  alias PanWeb.{AlternateFeed, Feed, Subscription}

  schema "backlog_feeds" do
    field :url, :string
    field :feed_generator, :string
    field :in_progress, :boolean, default: false
    belongs_to :user, PanWeb.User

    timestamps()
  end


  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:url, :in_progress, :feed_generator, :user_id])
    |> validate_required([:url])
  end


  def subscribe(backlog_feed) do
    case get_from_feed(backlog_feed.url) || get_from_alternative_feed(backlog_feed.url) do
      nil        -> nil
      podcast_id ->
        Subscription.get_or_insert(backlog_feed.user_id, podcast_id)
        Repo.delete!(backlog_feed)
    end
  end


  defp get_from_feed(url) do
    case (from f in Feed, where: f.self_link_url == ^url,
                          limit: 1)
         |> Repo.one do
      nil  -> nil
      feed -> feed.podcast_id
    end
  end


  defp get_from_alternative_feed(url) do
    case (from f in AlternateFeed, where: f.url == ^url,
                                   preload: :feed,
                                   limit: 1)
         |> Repo.one do
      nil            -> nil
      alternate_feed -> alternate_feed.feed.podcast_id
    end
  end
end
