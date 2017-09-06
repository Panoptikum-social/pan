defmodule Pan.OpmlParser.FeedBacklog do
  use Pan.Web, :controller

  def get_or_insert(url, user_id) do
    case Repo.get_by(PanWeb.FeedBacklog, url: url, user_id: user_id) do
      nil ->
        %PanWeb.FeedBacklog{url: url,
                         user_id: user_id,
                         in_progress: false}
        |> Repo.insert()
      feed ->
        {:ok, feed}
    end
  end
end
