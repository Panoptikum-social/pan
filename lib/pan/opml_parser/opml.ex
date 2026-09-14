defmodule Pan.OpmlParser.Opml do
  alias Pan.OpmlParser.Iterator
  require Logger

  def parse(path, user_id) do
    {:ok, feed_xml} = File.read(path)

    Logger.error("OPML- Import: Path: #{path}")

    # This is a user-uploaded file, so unlike a fetched podcast feed it's
    # directly attacker-controlled — strip any DOCTYPE before it reaches
    # xmerl. See Pan.Parser.Helpers.remove_doctype/1 for why.
    Pan.Parser.Helpers.remove_doctype(feed_xml)
    |> Quinn.parse()
    |> Iterator.parse(user_id)
  end
end
