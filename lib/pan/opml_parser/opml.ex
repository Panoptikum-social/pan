defmodule Pan.OpmlParser.Opml do
  alias Pan.OpmlParser.Iterator
  require Logger

  def parse(path, user_id) do
    {:ok, feed_xml} = File.read(path)

    Logger.error "\n\e[96m === OPML- Import: Path: " <> path <> " ===\e[0m"

    Quinn.parse(feed_xml)
    |> Iterator.parse(user_id)
  end
end