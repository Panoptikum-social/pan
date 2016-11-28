defmodule Pan.OPMLParser.Iterator do
  alias Pan.OPMLParser.Analyzer
  alias Pan.OPMLParser.Helpers

# We are done digging down
  def parse([], _user_id), do: nil

  def parse([head | tail], user_id) do
    if is_map(head) do
      Analyzer.call([head[:name], head[:attr], head[:value]], user_id)
    end
    parse(tail, user_id)
  end
end