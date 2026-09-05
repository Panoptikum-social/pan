defmodule Pan.Parser.Category do
  import Ecto.Query
  alias Pan.Parser.SsrfGuard
  alias Pan.Repo
  alias PanWeb.Category

  def get_or_insert(title, nil) do
    case Repo.one(from(c in Category, where: c.title == ^title and is_nil(c.parent_id))) do
      nil ->
        Repo.insert(%Category{title: title})

      category ->
        {:ok, category}
    end
  end

  def get_or_insert(title, parent_title) do
    {:ok, parent} = get_or_insert(parent_title, nil)

    case Repo.one(from(c in Category, where: c.title == ^title and c.parent_id == ^parent.id)) do
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
        categories_map
        # A malformed/empty <category> tag parses to a nil (or blank) title —
        # get_or_insert/2's query does `c.title == ^title`, and Ecto refuses
        # to build that comparison against a literal nil (would silently
        # match nothing in SQL anyway), raising instead of just skipping it.
        |> Enum.reject(fn {_, category_map} -> blank?(category_map[:title]) end)
        |> Enum.map(fn {_, category_map} ->
          {:ok, category} = get_or_insert(category_map[:title], category_map[:parent])
          category
        end)

      categories = Enum.uniq(categories)

      podcast = Repo.preload(podcast, :categories)

      Ecto.Changeset.change(podcast)
      |> Ecto.Changeset.put_assoc(:categories, podcast.categories ++ categories)
      |> Repo.update!()
    end
  end

  defp blank?(nil), do: true
  defp blank?(title), do: String.trim(title) == ""

  def fix() do
    podcasts = Repo.all(PanWeb.Podcast)
    podcasts = Repo.preload(podcasts, [:feeds, :categories])

    for podcast <- podcasts do
      headers = [
        "User-Agent":
          "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:51.0) Gecko/20100101 Firefox/51.0"
      ]

      options = [
        recv_timeout: 15_000,
        timeout: 15_000,
        hackney: [:insecure],
        ssl: [{:versions, [:"tlsv1.2"]}]
      ]

      for feed <- podcast.feeds do
        try do
          :ok = SsrfGuard.check(feed.self_link_url)

          %HTTPoison.Response{body: feed_xml} =
            HTTPoison.get!(feed.self_link_url, headers, options)

          feed_map = Quinn.parse(feed_xml)

          map = Pan.Parser.Iterator.parse(%{}, feed_map)
          podcast = Pan.Repo.preload(feed, :podcast).podcast
          Pan.Parser.Category.persist_many(map[:categories], podcast)
        catch
          :exit, _ -> :noop
          :error, _ -> :noop
        end
      end
    end
  end
end
