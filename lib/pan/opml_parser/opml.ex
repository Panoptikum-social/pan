defmodule Pan.OpmlParser.Opml do
  alias Pan.OpmlParser.Iterator
  require Logger

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
      feed_xml
      |> Quinn.parse()
      |> Iterator.parse(user_id)
    catch
      :exit, error ->
        Logger.error("OPML import failed for #{path}: " <> inspect(error))
        {:error, "Quinn error: " <> inspect(error)}
    end
  end
end
