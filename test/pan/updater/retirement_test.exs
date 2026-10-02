defmodule Pan.Updater.RetirementTest do
  @moduledoc """
  A podcast retires once its failure count reaches 10, against a real local
  HTTP server (TestServer).

  Not async: the SSRF guard has to let localhost through for these tests,
  and the async SSRF guard tests check that it doesn't by default.
  """
  use Pan.DataCase, async: false

  alias PanWeb.{Feed, Podcast}
  import Pan.Parser.MyDateTime, only: [now: 0]

  setup do
    Application.put_env(:pan, :ssrf_guard_allowed_hosts, ["localhost"])
    on_exit(fn -> Application.delete_env(:pan, :ssrf_guard_allowed_hosts) end)
    {:ok, _} = TestServer.start()
    TestServer.add("/feed.xml", via: :get, to: &Plug.Conn.resp(&1, 404, "Not Found"))
    :ok
  end

  defp failing_podcast(failure_count) do
    podcast =
      %Podcast{}
      |> Podcast.changeset(%{
        title: "Retirement Test Podcast #{System.unique_integer([:positive])}",
        update_intervall: 24,
        next_update: now(),
        failure_count: failure_count
      })
      |> Repo.insert!()

    # no_headers_available skips the HEAD check
    %Feed{podcast_id: podcast.id, no_headers_available: true}
    |> Feed.changeset(%{self_link_url: TestServer.url("/feed.xml")})
    |> Repo.insert!()

    podcast
  end

  defp update(podcast) do
    Pan.Updater.Podcast.import_new_episodes(podcast)
    Repo.get!(Podcast, podcast.id)
  end

  test "the 10th failure retires the podcast" do
    podcast = failing_podcast(9) |> update()

    assert podcast.failure_count == 10
    assert podcast.retired
  end

  test "a failure count already past 10 retires the podcast too" do
    podcast = failing_podcast(42) |> update()

    assert podcast.failure_count == 43
    assert podcast.retired
  end

  test "fewer than 10 failures don't retire" do
    podcast = failing_podcast(nil) |> update()

    assert podcast.failure_count == 1
    refute podcast.retired
  end
end
