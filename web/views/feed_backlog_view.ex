defmodule Pan.FeedBacklogView do
  use Pan.Web, :view
  alias Pan.Feed

  def best_matching_feed(url) do
    url
    |> String.split("/", parts: 3)
    |> List.last
    |> Feed.clean_and_best_matching()
  end
end
