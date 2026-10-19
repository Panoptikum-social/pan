defmodule Pan.OpmlParser.Opml do
  alias Pan.OpmlParser.{FeedBacklog, Iterator}
  alias Pan.Parser.XmlNames
  require Logger

  # a friend of the user has 1000 podcasts in their OPML
  @max_feeds 1500

  @doc """
  Puts the feeds of the OPML file at `path` into the feed backlog of
  `user_id`. Returns `{:ok, number of feeds}` or `{:error, message}`; a file
  with more than #{@max_feeds} feeds is refused as a whole.
  """
  def parse(path, user_id) do
    {:ok, feed_xml} = File.read(path)

    Logger.error("OPML- Import: Path: #{path}")

    # This is a user-uploaded file, so unlike a fetched podcast feed it's
    # directly attacker-controlled — strip any DOCTYPE before it reaches
    # xmerl. See Pan.Parser.Helpers.remove_doctype/1 for why.
    feed_xml =
      Pan.Parser.Helpers.fix_encoding(feed_xml)
      |> Pan.Parser.Helpers.remove_doctype()
      |> Pan.Parser.Helpers.remove_duplicate_xml_declarations()
      |> Pan.Parser.Helpers.normalize_nbsp()

    try do
      with :ok <- XmlNames.check(feed_xml),
           urls = feed_xml |> Quinn.parse() |> Iterator.parse() |> Enum.uniq(),
           :ok <- check_count(urls) do
        Enum.each(urls, &FeedBacklog.get_or_insert(&1, user_id))
        {:ok, length(urls)}
      end
    catch
      :exit, error ->
        Logger.error("OPML import failed for #{path}: " <> inspect(error))
        {:error, "Quinn error: " <> inspect(error)}
    end
  end

  defp check_count(urls) when length(urls) > @max_feeds,
    do: {:error, "The OPML has #{length(urls)} feeds, at most #{@max_feeds} can be imported."}

  defp check_count(_urls), do: :ok
end
