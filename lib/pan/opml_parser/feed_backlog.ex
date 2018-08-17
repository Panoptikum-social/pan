defmodule Pan.OpmlParser.FeedBacklog do
  alias Pan.Repo
  alias PanWeb.FeedBacklog

  def get_or_insert(url, user_id) do
    case Repo.get_by(PanWeb.FeedBacklog, url: url,
                                         user_id: user_id) do
      nil ->
        %FeedBacklog{url: url,
                     user_id: user_id,
                     in_progress: false}
        |> Repo.insert()
      feed ->
        {:ok, feed}
    end
  end
end
