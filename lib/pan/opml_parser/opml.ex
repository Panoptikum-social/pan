defmodule Pan.OpmlParser.Opml do
  alias Pan.OpmlParser.Iterator

  def parse(path, user_id) do
    {:ok, feed_xml} = File.read(path)

    IO.puts "\n\e[96m === Path: " <> path <> " ===\e[0m"

    Quinn.parse(feed_xml)
    |> Iterator.parse(user_id)
  end
end