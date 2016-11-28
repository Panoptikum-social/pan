defmodule Pan.OPMLParser.OPML do
  alias Pan.OPMLParser.Iterator

  def parse(path, user_id) do
    {:ok, feed_xml} = File.read(path)

    IO.puts "\n\e[96m === Path: " <> path <> " ===\e[0m"

    feed_map = Quinn.parse(feed_xml)
               |> Iterator.parse(user_id)
  end
end