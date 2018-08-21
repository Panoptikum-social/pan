defmodule PanWeb.Feed do
  use Pan.Web, :model
  alias Pan.Repo
  alias PanWeb.{AlternateFeed, Feed, Podcast}

  schema "feeds" do
    field :self_link_title, :string
    field :self_link_url, :string
    field :next_page_url, :string
    field :prev_page_url, :string
    field :first_page_url, :string
    field :last_page_url, :string
    field :hub_link_url, :string
    field :feed_generator, :string
    field :etag, :string
    field :last_modified, :naive_datetime
    field :trust_last_modified, :boolean
    field :no_headers_available, :boolean
    field :hash, :string
    timestamps()

    belongs_to :podcast, PanWeb.Podcast
    has_many :alternate_feeds, PanWeb.AlternateFeed, on_delete: :delete_all
  end


  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:self_link_url, :self_link_title, :next_page_url, :prev_page_url, :etag,
                     :first_page_url, :last_page_url, :hub_link_url, :feed_generator, :podcast_id,
                     :last_modified, :trust_last_modified, :no_headers_available, :hash])
    |> validate_required([:self_link_url])
    |> cast_assoc(:alternate_feeds)
  end


  def clean_and_best_matching(url) do
    url
    |> String.split("/", parts: 3)
    |> List.last
    |> String.replace("feeds.feedburner.com/", "")
    |> best_matching
  end


  def best_matching(url) do
    cond do
      feed = from(f in Feed, where: ilike(f.self_link_url, ^"%#{url}%"),
                             limit: 1)
             |> Repo.one() ->
        feed

      alternate_feed = from(a in AlternateFeed, where: ilike(a.url, ^"%#{url}%"),
                                                preload: :feed,
                                                limit: 1)
                       |> Repo.one() ->
        alternate_feed.feed

      podcast = from(p in Podcast, where: ilike(p.website, ^"%#{url}%"),
                                   preload: :feeds,
                                   limit: 1)
                |> Repo.one() ->
        List.first(podcast.feeds)

      String.contains?(url, "/") ->
        url
        |> String.reverse
        |> String.split("/", parts: 2)
        |> List.last
        |> String.reverse
        |> best_matching

      true ->
        nil
    end
  end
end
