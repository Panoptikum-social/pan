defmodule Pan.Parser.CategoryFix do

  def call() do
    podcasts = Pan.Repo.all(Pan.Podcast)
    podcasts = Pan.Repo.preload(podcasts, [:feeds, :categories])

    for {podcast, counter} <- Enum.with_index(podcasts) do
    IO.puts "============" <> to_string(counter)

      for feed <- podcast.feeds do
        try do
          %HTTPoison.Response{body: feed_xml} =
            HTTPoison.get!(feed.self_link_url,
                           [{"User-Agent",
                             "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/49.0.2623.75 Safari/537.36"}],
                           [follow_redirect: true, connect_timeout: 20000, recv_timeout: 20000, timeout: 20000])
          feed_map = Quinn.parse(feed_xml)

          map = Pan.Parser.Iterator.parse(%{}, feed_map)
          podcast = Pan.Repo.preload(feed, :podcast).podcast
          Pan.Parser.Category.assign_many(map[:categories], podcast)
        catch
          :exit, _ ->  IO.puts "ex"
          :timeout, _ -> IO.puts "t"
          :error, _ -> IO.puts "er"
        end
      end
    end
  end
end