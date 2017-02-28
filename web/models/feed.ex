defmodule Pan.Feed do
  use Pan.Web, :model
  alias Pan.Feed
  alias Pan.AlternateFeed
  alias Pan.Repo
  alias Pan.Podcast

  schema "feeds" do
    field :self_link_title, :string
    field :self_link_url, :string
    field :next_page_url, :string
    field :prev_page_url, :string
    field :first_page_url, :string
    field :last_page_url, :string
    field :hub_link_url, :string
    field :feed_generator, :string
    timestamps()

    belongs_to :podcast, Pan.Podcast
    has_many :alternate_feeds, Pan.AlternateFeed, on_delete: :delete_all
  end


  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:self_link_url, :self_link_title, :next_page_url, :prev_page_url,
                     :first_page_url, :last_page_url, :hub_link_url, :feed_generator, :podcast_id])
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
    # IO.puts("==========" <> url <> "========")
    cond do
      feed = Repo.all(from f in Feed, where: ilike(f.self_link_url, ^"%#{url}%"),
                                       limit: 1)
             |> List.first ->
        feed

      alternate_feed = Repo.all(from a in AlternateFeed, where: ilike(a.url, ^"%#{url}%"),
                                                         preload: :feed,
                                                         limit: 1)
                       |> List.first ->
        alternate_feed.feed

      podcast = Repo.one(from p in Podcast, where: ilike(p.website, ^"%#{url}%"),
                                            preload: :feeds) ->
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
