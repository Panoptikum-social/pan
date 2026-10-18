defmodule Pan.FeedProbeTest do
  @moduledoc """
  Pan.FeedProbe against a local HTTP server (TestServer). Not async: the
  SSRF guard has to let localhost through, see Pan.Updater.RedirectTest.
  Needs ImageMagick (convert/identify), like the thumbnails do, and ffmpeg
  for the audio probes.
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

  # A file of `seconds` of sine tone, e.g. "mp3" or "m4a" (no fast start).
  defp audio_file(extension, seconds, args) do
    path =
      Path.join(
        System.tmp_dir!(),
        "probe-test-#{System.unique_integer([:positive])}.#{extension}"
      )

    {_, 0} =
      System.cmd(
        "ffmpeg",
        ["-v", "error", "-f", "lavfi", "-i", "sine=frequency=440:duration=#{seconds}"] ++
          args ++ [path],
        stderr_to_stdout: true
      )

    body = File.read!(path)
    File.rm(path)
    body
  end

  defp audio_reads(path) do
    %{
      episodes: %{
        "e1" => %{
          title: "Episode 1",
          publishing_date: ~N[2026-01-01 00:00:00],
          enclosures: %{"x" => %{url: TestServer.url(path), length: "1", type: "audio/mpeg"}}
        }
      }
    }
  end

  test "audio: only the first megabyte, even from a server ignoring the range, across a redirect" do
    mp3 = audio_file("mp3", 130, ["-ac", "1", "-b:a", "128k"])
    assert byte_size(mp3) > 2_000_000

    # the plug runs in the server process, so the URL is built up front
    location = TestServer.url("/1.mp3")

    TestServer.add("/old.mp3",
      via: :get,
      to: fn conn ->
        conn
        |> Plug.Conn.put_resp_header("location", location)
        |> Plug.Conn.resp(302, "")
      end
    )

    TestServer.add("/1.mp3", via: :get, to: &Plug.Conn.resp(&1, 200, mp3))

    assert %{audio: [%{label: "“Episode 1”", result: {:ok, audio}}]} =
             Pan.FeedProbe.probe_audio(audio_reads("/old.mp3"))

    assert %{codec: "mp3", container: "mp3", channels: 1, sample_rate: 44_100} = audio
    assert audio.bit_rate == 128_000
    # 1 MB of 128 kbps is about 65 seconds, not the whole 130
    assert audio.seconds > 55 and audio.seconds < 75
    assert is_number(audio.loudness) and is_number(audio.true_peak)

    # check_my_feed has the audio rules (0.5.0 and later)
    {:ok, report} =
      CheckMyFeed.check_probes(%{audio: [%{label: "x", url: "x", result: {:ok, audio}}]})

    assert "apple.audio.bit_rate" in Enum.map(
             report.passed ++ report.findings,
             &(Map.get(&1, :id) || &1.rule_id)
           )
  end

  test "audio: an MP4 whose index sits after the first megabyte" do
    m4a = audio_file("m4a", 120, ["-c:a", "aac", "-b:a", "128k"])
    assert byte_size(m4a) > 1_048_576

    TestServer.add("/1.m4a", via: :get, to: &Plug.Conn.resp(&1, 200, m4a))

    assert %{audio: [%{result: {:error, :index_at_end}}]} =
             Pan.FeedProbe.probe_audio(audio_reads("/1.m4a"))
  end
end
