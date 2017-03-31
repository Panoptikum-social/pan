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
    Logger.error "\n\e[96m === Tag unknown: ==="
    Logger.error "Tag: " <> ~s/:"/ <> to_string(tag) <> ~s/"/
    Logger.error "Attr: " <> to_string(attr)
    Logger.error "Value: " <> to_string(value)
    Logger.error "=================\e[0m"
    raise "Tag unknown"
  end
end
