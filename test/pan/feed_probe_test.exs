defmodule Pan.FeedProbeTest do
  @moduledoc """
  Pan.FeedProbe against a local HTTP server (TestServer). Not async: the
  SSRF guard has to let localhost through, see Pan.Updater.RedirectTest.
  Needs ImageMagick (convert/identify), like the thumbnails do.
  """
  use ExUnit.Case, async: false

  setup do
    Application.put_env(:pan, :ssrf_guard_allowed_hosts, ["localhost"])
    on_exit(fn -> Application.delete_env(:pan, :ssrf_guard_allowed_hosts) end)
    {:ok, _} = TestServer.start()
    :ok
  end

  defp png(size) do
    path = Path.join(System.tmp_dir!(), "probe-test-#{System.unique_integer([:positive])}.png")
    {_, 0} = System.cmd("convert", ["-size", size, "xc:none", path])
    body = File.read!(path)
    File.rm(path)
    body
  end

  test "measures the artwork and asks for the media files" do
    TestServer.add("/cover.png", via: :get, to: &Plug.Conn.resp(&1, 200, png("1200x1000")))

    TestServer.add("/1.mp3",
      via: :head,
      to: fn conn ->
        conn
        |> Plug.Conn.put_resp_header("content-type", "audio/mpeg")
        |> Plug.Conn.put_resp_header("content-length", "999")
        |> Plug.Conn.resp(200, "")
      end
    )

    reads = %{
      image_url: TestServer.url("/cover.png"),
      episodes: %{
        "e1" => %{
          title: "Episode 1",
          publishing_date: ~N[2026-01-01 00:00:00],
          enclosures: %{
            "x" => %{url: TestServer.url("/1.mp3"), length: "123", type: "audio/mpeg"}
          }
        }
      }
    }

    probes = Pan.FeedProbe.probe(reads)

    assert [%{label: "Artwork", result: {:ok, image}}] = probes.artwork
    assert %{format: "PNG", width: 1200, height: 1000, alpha: true} = image

    assert [%{label: "“Episode 1”", feed_length: "123", result: {:ok, response}}] =
             probes.enclosures

    assert %{status: 200, length: 999, type: "audio/mpeg"} = response

    {:ok, report} = CheckMyFeed.check_probes(probes)
    ids = Enum.map(report.findings, & &1.rule_id)

    assert "apple.artwork.size" in ids
    assert "apple.artwork.square" in ids
    assert "apple.artwork.alpha" in ids
    assert "rss2.enclosure.length_matches" in ids
  end

  test "an artwork that isn't there" do
    TestServer.add("/missing.jpg", via: :get, to: &Plug.Conn.resp(&1, 404, "not found"))

    probes = Pan.FeedProbe.probe(%{image_url: TestServer.url("/missing.jpg"), episodes: %{}})
    assert [%{result: {:error, "HTTP 404"}}] = probes.artwork
    assert probes.enclosures == []
  end
end
