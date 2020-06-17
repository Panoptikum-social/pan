defmodule Pan.Parser.FeedBacklog do
  alias Pan.Repo

  def upload do
    stream = File.stream!("materials/backlog.xml", [:read, :utf8])
    Enum.each stream, fn(url) ->
      %PanWeb.FeedBacklog{url: url}
      |> Repo.insert()
    end
  end

  def delete_duplicates() do
    for backlogfeed <- Repo.all(PanWeb.FeedBacklog) do
      if Repo.get_by(PanWeb.Feed, self_link_url: backlogfeed.url), do: Repo.delete!(backlogfeed)
    end
  end
end
