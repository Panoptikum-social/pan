defmodule Pan.Parser.Category do
  use Pan.Web, :controller
  alias Pan.Repo
  alias Pan.Category


  def get_or_insert(title, nil) do
    case Repo.one(from c in Category, where: c.title == ^title and is_nil(c.parent_id)) do
      nil ->
        Repo.insert(%Category{title: title})
      category ->
        {:ok, category}
    end
  end

  def get_or_insert(title, parent_title) do
    {:ok, parent} = get_or_insert(parent_title, nil)

    case Repo.one(from c in Category, where: c.title == ^title and c.parent_id == ^parent.id) do
      nil ->
        %Category{title: title, parent_id: parent.id}
        |> Repo.insert()
      category ->
        {:ok, category}
    end
  end


  def persist_many(categories_map, podcast) do
    if categories_map do
      categories =
        Enum.map categories_map, fn({_, category_map}) ->
          {:ok, category} = get_or_insert(category_map[:title], category_map[:parent])
          category
        end
      categories = Enum.uniq(categories)

      podcast = Repo.preload(podcast, :categories)

      Ecto.Changeset.change(podcast)
      |> Ecto.Changeset.put_assoc(:categories, podcast.categories ++ categories)
      |> Repo.update!
    end
  end


  def fix() do
    podcasts = Pan.Repo.all(Pan.Podcast)
    podcasts = Pan.Repo.preload(podcasts, [:feeds, :categories])

    for {podcast, counter} <- Enum.with_index(podcasts) do
    IO.puts "============" <> to_string(counter)

    headers = ["User-Agent": "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:51.0) Gecko/20100101 Firefox/51.0"]
    options = [recv_timeout: 15_000, timeout: 15_000, hackney: [:insecure],
               ssl: [{:versions, [:'tlsv1.2']}]]

      for feed <- podcast.feeds do
        try do
          %HTTPoison.Response{body: feed_xml} = HTTPoison.get!(feed.self_link_url, headers, options)
          feed_map = Quinn.parse(feed_xml)

          map = Pan.Parser.Iterator.parse(%{}, feed_map)
          podcast = Pan.Repo.preload(feed, :podcast).podcast
          Pan.Parser.Category.persist_many(map[:categories], podcast)
        catch
          :exit, _ ->  IO.puts "ex"
          :timeout, _ -> IO.puts "t"
          :error, _ -> IO.puts "er"
        end
      end
    end
  end
end