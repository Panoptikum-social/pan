defmodule Pan.FeedProbe do
  @moduledoc """
  Measures what a feed points to, for check_my_feed's probe rules
  (`CheckMyFeed.check_probes/1`): the show's artwork and that of the newest
  episodes (downloaded and read with ImageMagick's identify), and the media
  files of the newest episodes (HEAD requests only, nothing is downloaded).

  One request at a time, never in parallel, each with a deadline.
  """

  alias Pan.Parser.Download

  @episodes 10
  @max_image_bytes 5_000_000
  @deadline 15_000
  @label_characters 60

  @doc "The probes for `CheckMyFeed.check_probes/1`, from Pan's parser map of the feed."
  def probe(reads) do
    episodes = newest_episodes(reads)
    %{artwork: artwork(reads, episodes), enclosures: enclosures(episodes)}
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
      %{label: label, url: url, result: within_deadline(fn -> measure_image(url) end)}
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
        enclosure = episode |> Map.get(:enclosures, %{}) |> Map.values() |> List.first(),
        not blank?(enclosure[:url]),
        do: %{
          label: title(episode),
          url: enclosure.url,
          feed_length: enclosure[:length],
          feed_type: enclosure[:type],
          result: within_deadline(fn -> head(enclosure.url) end)
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

  ## Helpers

  defp within_deadline(fun) do
    task = Task.async(fun)

    case Task.yield(task, @deadline) || Task.shutdown(task, :brutal_kill) do
      {:ok, result} -> result
      _timeout -> {:error, "no answer within #{div(@deadline, 1000)} seconds"}
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
