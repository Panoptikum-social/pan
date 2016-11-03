defmodule Pan.Parser.FeedBacklog do

  use Pan.Web, :controller

  def upload do
    stream = File.stream!("materials/backlog.xml", [:read, :utf8])
    Enum.each stream, fn(url) ->
      %Pan.FeedBacklog{url: url}
      |> Repo.insert()
    end
  end


  def get_missing_generators do
    feeds = Repo.all(from f in Pan.FeedBacklog, where: is_nil(f.feed_generator))

    for feed <- feeds do
      feed_generator = get_generator(feed.url)

      if is_bitstring(feed_generator) do
        Pan.FeedBacklog.changeset(feed, %{feed_generator: feed_generator})
        |> Repo.update()
      end
    end
  end


  def get_generator(url) do
    try do
      %HTTPoison.Response{body: feed_xml} = HTTPoison.get!(url,
        [{"User-Agent",
          "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/49.0.2623.75 Safari/537.36"}],
        [follow_redirect: true, connect_timeout: 20000, recv_timeout: 20000, timeout: 20000])

      feed_map = Quinn.parse(feed_xml)
      Quinn.find(feed_map, [:channel, :generator]).value

      # import SweetXml
      # xpath(feed_xml, ~x"//channel/generator/text()"s)
    catch
      :exit, _ ->  nil
      :timeout, _ -> nil
      :error, _ -> nil
    end
  end

  def delete_duplicates() do
    for backlogfeed <- Repo.all(Pan.FeedBacklog) do
      if Repo.get_by(Pan.Feed, self_link_url: backlogfeed.url), do: Repo.delete!(backlogfeed)
    end
  end
end