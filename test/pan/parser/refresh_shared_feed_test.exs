defmodule Pan.Parser.RefreshSharedFeedTest do
  use Pan.DataCase

  alias Pan.Parser.Persistor
  alias Pan.Repo
  alias PanWeb.{Feed, Podcast}

  defp insert_podcast_with_feed(title, url) do
    podcast =
      Repo.insert!(%Podcast{
        title: title,
        update_intervall: 10,
        next_update: ~N[2026-01-01 00:00:00]
      })

    Repo.insert!(%Feed{podcast_id: podcast.id, self_link_url: url})
    podcast
  end

  defp refresh(podcast, title, url) do
    Persistor.update_from_feed(%{title: title, feed: %{self_link_url: url}}, podcast,
      skip_episodes: true
    )
  end

  test "a podcast sharing its feed does not take over a new title" do
    successor = insert_podcast_with_feed("Sixers Talk", "https://feeds.example.com/sixers")
    old = insert_podcast_with_feed("Holding Court", "http://feeds.example.com/sixers")

    assert {:error, message} = refresh(old, "Sixers Talk", "https://feeds.example.com/sixers")
    assert message =~ "also belongs to podcast #{successor.id}"
    assert Repo.get!(Podcast, old.id).title == "Holding Court"
  end

  test "a podcast with its own feed may share its title with another podcast" do
    insert_podcast_with_feed("Deportes", "https://www.ivoox.com/deportes.xml")
    rfi = insert_podcast_with_feed("Deportes RFI", "https://www.rfi.fr/deportes.xml")

    assert {:ok, _message} = refresh(rfi, "Deportes", "https://www.rfi.fr/deportes.xml")
    assert Repo.get!(Podcast, rfi.id).title == "Deportes"
  end
end
