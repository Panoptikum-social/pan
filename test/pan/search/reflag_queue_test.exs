defmodule Pan.Search.ReflagQueueTest do
  use Pan.DataCase

  alias Pan.Repo
  alias Pan.Search.ReflagQueue
  alias PanWeb.{Episode, Podcast}

  defp insert_podcast(n) do
    podcast = Repo.insert!(%Podcast{title: "Reflag podcast #{n}", full_text: true})

    Repo.insert!(%Episode{
      podcast_id: podcast.id,
      title: "Episode #{n}",
      guid: "reflag-#{n}",
      full_text: true
    })

    podcast
  end

  defp flagged?(podcast) do
    Repo.get!(Podcast, podcast.id).full_text or
      Repo.get_by!(Episode, podcast_id: podcast.id).full_text
  end

  test "re-flags queued podcasts and their episodes, over several chunks and once per id" do
    podcasts = Enum.map(1..150, &insert_podcast/1)
    untouched = insert_podcast(0)
    ids = Enum.map(podcasts, & &1.id)

    # two merges in a row, sharing podcasts
    ReflagQueue.add(Enum.take(ids, 120))
    ReflagQueue.add(Enum.drop(ids, 60))
    ReflagQueue.flush()

    refute Enum.any?(podcasts, &flagged?/1)
    assert flagged?(untouched)
  end

  test "flush with nothing queued does nothing" do
    assert ReflagQueue.flush() == :ok
  end
end
