defmodule Pan.Parser.RssFeed do
  alias Pan.Parser.Iterator
  alias Pan.Parser.Persistor
  alias Pan.Parser.Download
  require Logger


  def initial_import(url, pagecount \\ 1) do
    case import_to_map(url) do
      {:ok, map} ->
        podcast_id = Persistor.initial_import(map, url)
        next_page_url = map[:feed][:next_page_url]
        pagecount = pagecount + 1

        if next_page_url != nil and pagecount < 26 do
          initial_import(next_page_url, pagecount)
        end

        {:ok, podcast_id}

      {:error, "Connection timeout"} ->
        {:error, "Connection timeout"}

      {:redirect, redirect_target} ->
        initial_import(redirect_target, pagecount)
    end
   end


  def import_to_map(url) do
    url = String.strip(url)
    Logger.info "\n\e[96m === Download from: #{url} ===\e[0m"

    case Download.download(url) do
      {:ok, feed_xml} ->
       feed_map = Pan.Parser.Helpers.remove_comments(feed_xml)
                  |> Pan.Parser.Helpers.remove_extra_angle_brackets()
                  |> Pan.Parser.Helpers.fix_character_code_strings()
                  |> String.trim()
                  |> Quinn.parse()

        map = %{feed: %{self_link_title: "Feed", self_link_url: url},
                        title: Enum.at(String.split(url, "/"), 2)}
              |> Iterator.parse(feed_map)
        {:ok, map}

      {:redirect, redirect_target} ->
        {:redirect, redirect_target}

      {:error, reason} ->
        {:error, reason}
    end
  end


# Convenience function for runtime measurement
  def measure_runtime(function) do
    function
    |> :timer.tc
    |> elem(0)
    |> Kernel./(1_000_000)
  end
end