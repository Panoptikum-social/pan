defmodule PanWeb.PodcastMergeTest do
  use Pan.DataCase

  alias Pan.Repo

  alias PanWeb.{
    AlternateFeed,
    Enclosure,
    Episode,
    Category,
    Community,
    Feed,
    FormerPodcast,
    Like,
    Podcast,
    PodcastMerge,
    Subscription,
    User
  }

  defp insert_user do
    n = System.unique_integer([:positive])
    Repo.insert!(%User{name: "Test", username: "merge_#{n}", email: "merge_#{n}@example.com"})
  end

  defp insert_podcast(title, url, attrs \\ []) do
    podcast =
      %Podcast{title: title, update_intervall: 10, next_update: ~N[2026-01-01 00:00:00]}
      |> struct(attrs)
      |> Repo.insert!()

    feed = Repo.insert!(%Feed{podcast_id: podcast.id, self_link_url: url})
    {podcast, feed}
  end

  defp insert_episode(podcast, guid, enclosure_url) do
    episode = Repo.insert!(%Episode{podcast_id: podcast.id, title: "Episode #{guid}", guid: guid})
    Repo.insert!(%Enclosure{episode_id: episode.id, url: enclosure_url})
    episode
  end

  defp enclosure_urls(episode) do
    from(e in Enclosure, where: e.episode_id == ^episode.id, select: e.url, order_by: e.url)
    |> Repo.all()
  end

  test "merges the ogg feed of a show into its mp3 feed" do
    {mp3, mp3_feed} = insert_podcast("Show", "https://show.example.com/feed/mp3")
    {ogg, ogg_feed} = insert_podcast("Show (Ogg)", "https://show.example.com/feed/ogg")
    Repo.insert!(%AlternateFeed{feed_id: ogg_feed.id, url: "http://old.example.com/ogg"})

    shared = insert_episode(mp3, "ep-1", "https://show.example.com/1.mp3")
    insert_episode(ogg, "ep-1", "https://show.example.com/1.ogg")
    insert_episode(ogg, "ep-2", "https://show.example.com/2.ogg")

    assert {:ok, message} = PodcastMerge.merge(ogg.id, mp3.id)
    assert message =~ "1 episodes moved, 1 merged"

    refute Repo.get(Podcast, ogg.id)
    refute Repo.get(Feed, ogg_feed.id)

    assert enclosure_urls(shared) == [
             "https://show.example.com/1.mp3",
             "https://show.example.com/1.ogg"
           ]

    episode_guids =
      from(e in Episode, where: e.podcast_id == ^mp3.id, select: e.guid, order_by: e.guid)
      |> Repo.all()

    assert episode_guids == ["ep-1", "ep-2"]

    alternate_urls =
      from(a in AlternateFeed, where: a.feed_id == ^mp3_feed.id, select: a.url) |> Repo.all()

    assert "https://show.example.com/feed/ogg" in alternate_urls
    assert "http://old.example.com/ogg" in alternate_urls
    assert Repo.get!(Podcast, mp3.id).episodes_count == 2
  end

  test "subscriptions and episode likes move without duplicates" do
    {a, _} = insert_podcast("A", "https://a.example.com/feed")
    {b, _} = insert_podcast("B", "https://b.example.com/feed")
    a_episode = insert_episode(a, "shared", "https://a.example.com/1.mp3")
    b_episode = insert_episode(b, "shared", "https://b.example.com/1.mp3")

    both = insert_user()
    only_b = insert_user()
    Repo.insert!(%Subscription{user_id: both.id, podcast_id: a.id})
    Repo.insert!(%Subscription{user_id: both.id, podcast_id: b.id})
    Repo.insert!(%Subscription{user_id: only_b.id, podcast_id: b.id})
    Repo.insert!(%Like{enjoyer_id: both.id, episode_id: a_episode.id})
    Repo.insert!(%Like{enjoyer_id: both.id, episode_id: b_episode.id})
    Repo.insert!(%Like{enjoyer_id: only_b.id, episode_id: b_episode.id})

    assert {:ok, _message} = PodcastMerge.merge(b.id, a.id)

    subscribers =
      from(s in Subscription,
        where: s.podcast_id == ^a.id,
        select: s.user_id,
        order_by: s.user_id
      )
      |> Repo.all()

    assert subscribers == Enum.sort([both.id, only_b.id])

    likers =
      from(l in Like,
        where: l.episode_id == ^a_episode.id,
        select: l.enjoyer_id,
        order_by: l.enjoyer_id
      )
      |> Repo.all()

    assert likers == Enum.sort([both.id, only_b.id])
  end

  test "the target takes over the owner, different owners are refused" do
    owner = insert_user()
    {a, _} = insert_podcast("A", "https://a.example.com/feed")
    {b, _} = insert_podcast("B", "https://b.example.com/feed", user_id: owner.id)

    assert {:ok, _message} = PodcastMerge.merge(b.id, a.id)
    assert Repo.get!(Podcast, a.id).user_id == owner.id

    {c, _} = insert_podcast("C", "https://c.example.com/feed", user_id: insert_user().id)
    assert {:error, message} = PodcastMerge.merge(c.id, a.id)
    assert message =~ "different users"
    assert Repo.get(Podcast, c.id)
  end

  test "refuses to merge a podcast into itself" do
    {a, _} = insert_podcast("A", "https://a.example.com/feed")
    assert {:error, _message} = PodcastMerge.merge(a.id, a.id)
  end

  defp put_in_community(podcast) do
    n = System.unique_integer([:positive])
    category = Repo.insert!(%Category{title: "Community category #{n}"})
    Repo.insert!(%Community{title: "Community #{n}", category_id: category.id})
    Repo.insert_all("categories_podcasts", [%{category_id: category.id, podcast_id: podcast.id}])
  end

  test "records the merged podcast as former podcast, earlier ones follow along" do
    {a, _} = insert_podcast("A", "https://a.example.com/feed")
    {b, _} = insert_podcast("B", "https://b.example.com/feed")
    {c, _} = insert_podcast("C", "https://c.example.com/feed")

    assert {:ok, _message} = PodcastMerge.merge(c.id, b.id)
    assert {:ok, _message} = PodcastMerge.merge(b.id, a.id)

    assert %FormerPodcast{title: "B", feed_url: "https://b.example.com/feed", new_id: new_id} =
             Repo.get(FormerPodcast, b.id)

    assert new_id == a.id
    assert Repo.get(FormerPodcast, c.id).new_id == a.id

    {detail, meta} = FormerPodcast.not_found(c.id)
    assert detail =~ "(C) was merged into the podcast with Panoptikum ID #{a.id}"
    assert meta == %{new_id: a.id}
  end

  test "a community podcast is only merged into a podcast of a community" do
    {a, _} = insert_podcast("A", "https://a.example.com/feed")
    {b, _} = insert_podcast("B", "https://b.example.com/feed")
    put_in_community(b)

    assert {:error, message} = PodcastMerge.merge(b.id, a.id)
    assert message =~ "merge #{a.id} into #{b.id} instead"
    assert Repo.get(Podcast, b.id)

    assert {:ok, _message} = PodcastMerge.merge(a.id, b.id)
  end
end
