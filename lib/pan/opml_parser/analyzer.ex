defmodule Pan.OpmlParser.Analyzer do
  alias Pan.OpmlParser.Iterator
  require Logger

  defdelegate dm(left, right), to: Pan.Parser.Helpers, as: :deep_merge

#wrappers to dive into
  def call([:opml, _, value], user_id), do: Iterator.parse(value, user_id)
  def call([:body, _, value], user_id), do: Iterator.parse(value, user_id)


# feeds from BeyondPod

  def call([:outline, attr, value], user_id) do
    case attr[:type] do
      "rss" ->
        Pan.OpmlParser.FeedBacklog.get_or_insert(attr[:xmlUrl], user_id)
      "atom" ->
        nil
      nil ->
        Iterator.parse(value, user_id)
    end
  end

# tags to ignore
  def call([tag_atom, _, _], _user_id) when tag_atom in [
    :head
  ], do: nil


  def call([tag, attr, value], _user_id) do
    Logger.error "=== Tag unknown: ==="
    Logger.error ~s(Tag: :"#{tag}")
    Logger.error "Attr: #{inspect attr}"
    Logger.error "Value: #{inspect value}"
    raise "Tag unknown"
  end
end
