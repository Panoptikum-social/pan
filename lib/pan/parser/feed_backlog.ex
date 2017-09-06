defmodule Pan.Parser.FeedBacklog do

  use Pan.Web, :controller

  def upload do
    stream = File.stream!("materials/backlog.xml", [:read, :utf8])
    Enum.each stream, fn(url) ->
      %PanWeb.FeedBacklog{url: url}
      |> Repo.insert()
    end
  end


  def get_missing_generators do
    feeds = Repo.all(from f in PanWeb.FeedBacklog, where: is_nil(f.feed_generator))

    for feed <- feeds do
      feed_generator = get_generator(feed.url)

      if is_bitstring(feed_generator) do
        PanWeb.FeedBacklog.changeset(feed, %{feed_generator: feed_generator})
        |> Repo.update()
      end
    end
  end


  def get_generator(url) do
    headers = ["User-Agent": "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:51.0) Gecko/20100101 Firefox/51.0"]
    options = [recv_timeout: 15_000, timeout: 15_000, hackney: [:insecure],
               ssl: [{:versions, [:'tlsv1.2']}]]

    try do
      %HTTPoison.Response{body: feed_xml} = HTTPoison.get!(url, headers, options)
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
    for backlogfeed <- Repo.all(PanWeb.FeedBacklog) do
      if Repo.get_by(PanWeb.Feed, self_link_url: backlogfeed.url), do: Repo.delete!(backlogfeed)
    end
  end
end