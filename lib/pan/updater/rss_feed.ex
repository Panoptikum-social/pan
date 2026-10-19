defmodule Pan.Updater.RssFeed do
  alias Pan.Parser.FeedXml
  alias Pan.Updater.{Feed, Filter}

  def import_to_map(feed_xml, feed, podcast_id \\ 0, forced \\ false) do
    url = String.trim(feed.self_link_url)

    with feed_xml <- FeedXml.clean_xml(feed_xml),
         {:ok, "go on"} <- Feed.hash_changed(feed_xml, feed, forced),
         {:ok, feed_map} <- xml_to_map(feed_xml, podcast_id),
         {:ok, reduced_map} <- Filter.only_new_items_and_new_feed_url(feed_map, podcast_id) do
      try do
        FeedXml.parse_to_map(reduced_map, url)
      rescue
        e ->
          reraise("#{Exception.message(e)} when importing podcast #{podcast_id}", __STACKTRACE__)
      end
    else
      {:done, "nothing to do"} -> {:done, "nothing to do"}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Channel title and all episode titles of a feed, unlike import_to_map/4
  not reduced to the new episodes. For Pan.Updater.Succession.
  """
  def titles(feed_xml) do
    case feed_xml |> FeedXml.clean_xml() |> FeedXml.xml_to_map() do
      {:ok, quinn_map} ->
        {:ok, map} = FeedXml.parse_to_map(quinn_map, "")
        episodes = map[:episodes] || %{}
        {map[:title], for({_key, episode} <- episodes, do: episode[:title])}

      {:error, _reason} ->
        {nil, []}
    end
  end

  # the core's error, prefixed with the podcast for logs and last_error_message
  defp xml_to_map(feed_xml, podcast_id) do
    with {:error, message} <- FeedXml.xml_to_map(feed_xml),
         do: {:error, "Podcast: #{podcast_id} #{message}"}
  end
end
