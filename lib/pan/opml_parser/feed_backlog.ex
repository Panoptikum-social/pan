defmodule Pan.OpmlParser.FeedBacklog do
  use Pan.Web, :controller

  def find_or_create(url, user_id) do
    case Repo.get_by(Pan.FeedBacklog, url: url, user_id: user_id) do
      nil ->
        %Pan.FeedBacklog{url: url,
                         user_id: user_id,
                         in_progress: true}
        |> Repo.insert()
      feed ->
        {:ok, feed}
    end
  end
end
