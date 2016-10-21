defmodule Pan.Parser.Cat do
  use Pan.Web, :controller
  alias Pan.Repo
  alias Pan.Podcast
  alias Pan.Category
  import SweetXml

  def fix() do
    podcasts = Repo.all(Podcast)
    podcasts = Repo.preload(podcasts, [:feeds, :categories])

    for {podcast, counter} <- Enum.with_index(podcasts) do
    IO.puts "============" <> to_string(counter)
      for feed <- podcast.feeds do
        try do
          %HTTPoison.Response{body: xml} = HTTPoison.get!(feed.self_link_url, [],
                                                          [follow_redirect: true,
                                                           connect_timeout: 20000,
                                                           recv_timeout: 20000,
                                                           timeout: 20000])
          categories = xml
                 |> xpath(~x"//channel/itunes:category"l,
                          title: ~x"./@text"s,
                          subtitle: ~x"./itunes:category/@text"s)

          for xml_category <- categories do
            category =
              if xml_category.subtitle == "" do
                Repo.get_by(Category, title: xml_category.title)
              else
                Repo.get_by(Category, title: xml_category.subtitle)
              end
              |> Repo.preload(:podcasts)

            category
            |> Ecto.Changeset.change()
            |> Ecto.Changeset.put_assoc(:podcasts, [podcast | category.podcasts])
            |> Repo.update!
          end
        catch
          :exit, _ ->  IO.puts "ex"
          :timeout, _ -> IO.puts "t"
          :error, _ -> IO.puts "er"
        end
      end
    end
  end
end