defmodule Pan.FeedProbe do
  @moduledoc """
  Measures what a feed points to, for check_my_feed's probe rules
  (`CheckMyFeed.check_probes/1`): the show's artwork and that of the newest
  episodes (downloaded and read with ImageMagick's identify), the media
  files of the newest episodes (HEAD requests only), and, separately, the
  audio of the newest episodes from the first megabyte of each file (read
  with ffprobe and ffmpeg's ebur128 filter).

  One request at a time, never in parallel, each with a deadline.
  """

  alias Pan.Parser.{Download, SsrfGuard}

  @episodes 10
  @max_image_bytes 5_000_000
  @deadline 15_000
  @label_characters 60
  @audio_episodes 3
  @audio_bytes 1_048_576
  @audio_deadline 30_000
  @max_redirects 5
  @user_agent "Mozilla/5.0 (compatible; Panoptikum; +https://panoptikum.social/)"

  @doc "The probes for `CheckMyFeed.check_probes/1`, from Pan's parser map of the feed."
  def probe(reads) do
    episodes = newest_episodes(reads)
    %{artwork: artwork(reads, episodes), enclosures: enclosures(episodes)}
  end

  @doc "The audio probes for `CheckMyFeed.check_probes/1`: the newest episodes' first megabyte."
  def probe_audio(reads) do
    audio =
      for episode <- reads |> newest_episodes() |> Enum.take(@audio_episodes),
          enclosure = first_enclosure(episode),
          not blank?(enclosure[:url]),
          do: %{
            label: title(episode),
            url: enclosure.url,
            result: within_deadline(fn -> measure_audio(enclosure.url) end, @audio_deadline)
          }

    %{audio: audio}
  end

  defp newest_episodes(reads) do
    reads
    |> Map.get(:episodes, %{})
    |> Map.values()
    |> Enum.sort_by(&(&1[:publishing_date] || ~N[0000-01-01 00:00:00]), {:desc, NaiveDateTime})
    |> Enum.take(@episodes)
  end

  ## Artwork

  defp artwork(reads, episodes) do
    show = reads[:image_url]

    targets =
      [{"Artwork", show}] ++
        for episode <- episodes, do: {"Artwork of #{title(episode)}", episode[:image_url]}

    targets
    |> Enum.reject(fn {_label, url} -> blank?(url) end)
    |> Enum.uniq_by(fn {_label, url} -> url end)
    |> Enum.map(fn {label, url} ->
      %{label: label, url: url, result: within_deadline(fn -> measure_image(url) end, @deadline)}
    end)
  end

  defp measure_image(url) do
    case Download.get(url, follow_redirect: true) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}}
      when byte_size(body) > @max_image_bytes ->
        {:error, "it is larger than #{div(@max_image_bytes, 1_000_000)} MB"}

      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        identify(body)

      {:ok, %HTTPoison.Response{status_code: status}} ->
        {:error, "HTTP #{status}"}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, inspect(reason)}

      {:error, reason} ->
        {:error, to_string(reason)}
    end
  end

  # [0]: only the first frame of an animated or multi-page image.
  defp identify(body) do
    path = Path.join(System.tmp_dir!(), "pan-probe-#{System.unique_integer([:positive])}")
    File.write!(path, body)

    result =
      System.cmd(
        "identify",
        ["-format", "%m|%w|%h|%[channels]|%[colorspace]|%x|%U\n", path <> "[0]"],
        stderr_to_stdout: true
      )

    File.rm(path)

    case result do
      {output, 0} -> output |> String.split("\n") |> hd() |> parse_identify()
      {_output, _status} -> {:error, "it is not an image ImageMagick can read"}
    end
  end

  defp parse_identify(line) do
    case String.split(line, "|") do
      [format, width, height, channels, colorspace, density, units] ->
        {:ok,
         %{
           format: format,
           width: String.to_integer(width),
           height: String.to_integer(height),
           colorspace: colorspace,
           alpha: channels |> String.split() |> hd() |> String.ends_with?("a"),
           dpi: dpi(density, units)
         }}

      _other ->
        {:error, "ImageMagick's answer couldn't be read: #{inspect(line)}"}
    end
  end

  # Without a unit (common in JPEGs) the density says nothing about dpi.
  defp dpi(density, units) do
    case {Float.parse(density), units} do
      {{value, _rest}, "PixelsPerInch"} -> value
      {{value, _rest}, "PixelsPerCentimeter"} -> value * 2.54
      _unknown -> nil
    end
  end

  ## Enclosures

  defp enclosures(episodes) do
    for episode <- episodes,
        enclosure = first_enclosure(episode),
        not blank?(enclosure[:url]),
        do: %{
          label: title(episode),
          url: enclosure.url,
          feed_length: enclosure[:length],
          feed_type: enclosure[:type],
          result: within_deadline(fn -> head(enclosure.url) end, @deadline)
        }
  end

  defp head(url) do
    case Download.head(url) do
      {:ok, %HTTPoison.Response{status_code: status, headers: headers}} ->
        {:ok,
         %{status: status, length: content_length(headers), type: header(headers, "content-type")}}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, inspect(reason)}

      {:error, reason} ->
        {:error, to_string(reason)}
    end
  end

  defp content_length(headers) do
    case Integer.parse(header(headers, "content-length") || "") do
      {length, ""} -> length
      _ -> nil
    end
  end

  defp header(headers, name) do
    Enum.find_value(headers, fn {key, value} -> if String.downcase(key) == name, do: value end)
  end

  ## Audio

  defp measure_audio(url) do
    with {:ok, bytes} <- first_bytes(url, @max_redirects) do
      path = Path.join(System.tmp_dir!(), "pan-probe-#{System.unique_integer([:positive])}")
      File.write!(path, bytes)
      result = audio_facts(path, bytes)
      File.rm(path)
      result
    end
  end

  # The first @audio_bytes of a file: a range request, and reading stops there
  # even if the server ignores the range. Redirects are followed by hand so
  # that every hop passes the SSRF guard.
  defp first_bytes(_url, 0), do: {:error, "too many redirects"}

  defp first_bytes(url, hops) do
    headers = [{"Range", "bytes=0-#{@audio_bytes - 1}"}, {"User-Agent", @user_agent}]
    options = [stream_to: self(), async: :once, recv_timeout: 10_000, timeout: 10_000]

    with :ok <- SsrfGuard.check(url),
         {:ok, %HTTPoison.AsyncResponse{id: id} = response} <-
           HTTPoison.get(url, headers, options) do
      read_first(response, url, hops, nil, [], 0, id)
    else
      {:error, %HTTPoison.Error{reason: reason}} -> {:error, inspect(reason)}
      {:error, reason} -> {:error, to_string(reason)}
    end
  end

  defp read_first(response, url, hops, status, chunks, size, id) do
    receive do
      %HTTPoison.AsyncStatus{id: ^id, code: code} ->
        HTTPoison.stream_next(response)
        read_first(response, url, hops, code, chunks, size, id)

      %HTTPoison.AsyncHeaders{id: ^id, headers: headers} when status in 300..399 ->
        close(id)

        case header(headers, "location") do
          nil -> {:error, "HTTP #{status} without a location"}
          location -> first_bytes(url |> URI.merge(location) |> to_string(), hops - 1)
        end

      %HTTPoison.AsyncHeaders{id: ^id} when status in [200, 206] ->
        HTTPoison.stream_next(response)
        read_first(response, url, hops, status, chunks, size, id)

      %HTTPoison.AsyncHeaders{id: ^id} ->
        close(id)
        {:error, "HTTP #{status}"}

      %HTTPoison.AsyncChunk{id: ^id, chunk: chunk} when size + byte_size(chunk) >= @audio_bytes ->
        close(id)
        bytes = IO.iodata_to_binary(Enum.reverse([chunk | chunks]))
        {:ok, binary_part(bytes, 0, @audio_bytes)}

      %HTTPoison.AsyncChunk{id: ^id, chunk: chunk} ->
        HTTPoison.stream_next(response)
        read_first(response, url, hops, status, [chunk | chunks], size + byte_size(chunk), id)

      %HTTPoison.AsyncEnd{id: ^id} ->
        {:ok, IO.iodata_to_binary(Enum.reverse(chunks))}

      %HTTPoison.Error{id: ^id, reason: reason} ->
        {:error, inspect(reason)}
    after
      15_000 ->
        close(id)
        {:error, "no data within 15 seconds"}
    end
  end

  defp close(id) when is_pid(id), do: :hackney.close(id)
  defp close(_id), do: :ok

  defp audio_facts(path, bytes) do
    args = [
      "-v",
      "error",
      "-show_entries",
      "format=format_name:stream=codec_type,codec_name,sample_rate,channels,bit_rate",
      "-of",
      "json",
      path
    ]

    with {json, 0} <- System.cmd("ffprobe", args, stderr_to_stdout: true),
         {:ok, %{"format" => format, "streams" => streams}} <- Jason.decode(json),
         %{} = stream <- Enum.find(streams, &(&1["codec_type"] == "audio")) do
      {loudness, true_peak, seconds} = loudness(path)

      {:ok,
       %{
         codec: stream["codec_name"],
         container: container(format["format_name"]),
         sample_rate: to_integer(stream["sample_rate"]),
         channels: stream["channels"],
         bit_rate: to_integer(stream["bit_rate"]),
         loudness: loudness,
         true_peak: true_peak,
         seconds: seconds
       }}
    else
      _unreadable ->
        if mp4?(bytes),
          do: {:error, :index_at_end},
          else: {:error, "it is not an audio file ffprobe can read"}
    end
  end

  # Integrated loudness and true peak from ebur128's summary at the end, and
  # its last running time: how much audio the first megabyte held (ffprobe's
  # duration is the whole episode's, read from the file's header).
  defp loudness(path) do
    args = ["-hide_banner", "-nostats", "-i", path, "-af", "ebur128=peak=true", "-f", "null", "-"]
    {output, _status} = System.cmd("ffmpeg", args, stderr_to_stdout: true)

    {last_number(~r/I:\s+(-?[\d.]+) LUFS/, output),
     last_number(~r/Peak:\s+(-?[\d.]+) dBFS/, output), last_number(~r/\bt:\s*([\d.]+)/, output)}
  end

  defp last_number(regex, output) do
    case Regex.scan(regex, output) do
      [] -> nil
      matches -> matches |> List.last() |> Enum.at(1) |> to_float()
    end
  end

  defp container("mp3"), do: "mp3"
  defp container("aac"), do: "adts"

  defp container(format_name) when is_binary(format_name) do
    if String.contains?(format_name, "mp4"), do: "mp4", else: format_name
  end

  defp container(_format_name), do: nil

  # ISO base media files (MP4, M4A) start with a size and "ftyp".
  defp mp4?(<<_size::binary-size(4), "ftyp", _rest::binary>>), do: true
  defp mp4?(_bytes), do: false

  defp to_integer(nil), do: nil

  defp to_integer(value) do
    case Integer.parse(value) do
      {integer, _rest} -> integer
      :error -> nil
    end
  end

  defp to_float(nil), do: nil

  defp to_float(value) do
    case Float.parse(value) do
      {float, _rest} -> float
      :error -> nil
    end
  end

  ## Helpers

  defp first_enclosure(episode),
    do: episode |> Map.get(:enclosures, %{}) |> Map.values() |> List.first()

  defp within_deadline(fun, deadline) do
    task = Task.async(fun)

    case Task.yield(task, deadline) || Task.shutdown(task, :brutal_kill) do
      {:ok, result} -> result
      _timeout -> {:error, "no answer within #{div(deadline, 1000)} seconds"}
    end
  end

  defp title(episode) do
    case episode[:title] do
      nil -> "an episode without title"
      title -> "“" <> String.slice(title, 0, @label_characters) <> "”"
    end
  end

  defp blank?(value), do: value in [nil, ""]
end
