defmodule Pan.Parser.Iterator do
  alias Pan.Parser.Analyzer
  alias Pan.Parser.Helpers
  require Logger

# Actual feed parsing: Now the fun begins
  def parse(map, context \\ "tag", tags)

# We are done digging down
  def parse(map, _, []), do: map

  def parse(map, "owner", [head | tail]) do
    owner_map =
      if is_map(head) do
        Analyzer.call(map, "owner", [head[:name], head[:attr], head[:value]])
      else
        %{email: head}
      end

    Helpers.deep_merge(map, %{owner: owner_map})
    |> parse("owner", tail)
  end


  def parse(map, "chapter", [head | tail]) do
    chapter_map = Analyzer.call("chapter", [head[:name], head[:attr], head[:value]])

    Helpers.deep_merge(map, %{chapters: chapter_map})
    |> parse("chapter", tail)
  end


  def parse(map, context, [head | tail]) do
    if is_map(head) do
      podcast_map =
        case Analyzer.call(map, context, [head[:name], head[:attr], head[:value]]) do
          {:error, "tag unknown"} ->
            Logger.error "Feed_url: " <> map[:feed][:self_link_url]
            raise "Tag unknown"
          map -> map
        end

      Helpers.deep_merge(map, podcast_map)
      |> parse(context, tail)
    else
      parse(map, context, tail)
    end
  end

# We are done digging down
  def parse(map, _, [], _), do: map

  def parse(map, "contributor", [head | tail], guid) do
    contributor_map = Analyzer.call("contributor", [head[:name], head[:attr], head[:value]])

    Pan.Parser.Helpers.deep_merge(map, %{contributors: %{String.to_atom(guid) => contributor_map}})
    |> parse("contributor", tail, guid)
  end


  def parse(map, "episode", [head | tail], guid) do
    if is_map(head) do
      episode_map =
        case Analyzer.call(map, "episode", [head[:name], head[:attr], head[:value]]) do
          {:error, "tag unknown"} ->
            Logger.error "Feed_url: " <> map[:feed][:self_link_url]
            raise "Tag unknown"
          map -> map
        end

      Helpers.deep_merge(map, %{episodes: %{String.to_atom(guid) => episode_map}})
      |> parse("episode", tail, guid)
    else
      parse(map, "episode", tail, guid)
    end
  end


  def parse(map, "category", [head | tail], category_title) do
    category_map = Analyzer.call("category", [head[:name], head[:attr], head[:value]], category_title)

    Helpers.deep_merge(map, category_map)
    |> parse("category", tail, category_title)
  end


  def parse(map, "episode-contributor", [head | tail], contributor_uuid) do
    contributor_map = Analyzer.call("episode-contributor", [head[:name], head[:attr], head[:value]])

    Helpers.deep_merge(map, %{contributors: %{contributor_uuid => contributor_map}})
    |> parse("episode-contributor", tail, contributor_uuid)
  end
end