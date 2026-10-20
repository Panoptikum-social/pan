defmodule Pan.AppleCategories do
  @moduledoc """
  Apple Podcasts' current category list, fetched from the iTunes genre
  service (genre 26, Podcasts). The service isn't officially documented but
  has been stable for years; if it fails, no flag changes.

  `update_flags/1` sets `apple` on the categories matching the list: a top
  level category by its title, a subcategory by its title below the matching
  top level one, both found the way the parser finds them
  (`Pan.Parser.Category.matching/1`). All other categories lose the flag.
  Apple categories can't be deleted, merged away or moved on the merge page.
  """
  import Ecto.Query
  alias Pan.Parser.Download
  alias Pan.Repo
  alias PanWeb.Category

  @url "https://itunes.apple.com/WebObjects/MZStoreServices.woa/ws/genres?id=26"

  @doc "Fetches the list and updates the flags, see `update_flags/1`."
  def update do
    with {:ok, list} <- fetch(), do: {:ok, update_flags(list)}
  end

  @doc "`{:ok, [{title, [subcategory title]}]}` or `{:error, message}`."
  def fetch do
    with {:ok, %HTTPoison.Response{status_code: 200, body: body}} <-
           Download.get(@url, follow_redirect: true),
         {:ok, %{"26" => %{"subgenres" => %{} = genres}}} <- Jason.decode(body) do
      {:ok,
       for {_id, genre} <- genres do
         {genre["name"], for({_id, sub} <- genre["subgenres"] || %{}, do: sub["name"])}
       end}
    else
      {:ok, %HTTPoison.Response{status_code: status}} ->
        {:error, "Apple answered with status #{status}."}

      {:ok, _other} ->
        {:error, "Apple's answer has an unexpected format."}

      {:error, reason} ->
        {:error, "Apple's category list could not be fetched: #{inspect(reason)}"}
    end
  end

  @doc """
  Flags the categories on `list` and unflags all others. Returns how many
  categories are Apple ones now, how many were newly flagged and unflagged,
  and the names on Apple's list without a category here (yet).
  """
  def update_flags(list) do
    matches =
      Enum.flat_map(list, fn {title, subtitles} ->
        top = match(title, nil)
        [{title, top} | Enum.map(subtitles, &{title <> " › " <> &1, top && match(&1, top.id)})]
      end)

    ids = for {_name, %Category{id: id}} <- matches, do: id

    {flagged, _} =
      from(c in Category, where: c.id in ^ids and not c.apple)
      |> Repo.update_all(set: [apple: true])

    {unflagged, _} =
      from(c in Category, where: c.id not in ^ids and c.apple)
      |> Repo.update_all(set: [apple: false])

    %{
      apple: length(ids),
      flagged: flagged,
      unflagged: unflagged,
      missing: for({name, nil} <- matches, do: name)
    }
  end

  defp match(title, parent_id) do
    title
    |> String.trim()
    |> Pan.Parser.Category.matching()
    |> where_parent(parent_id)
    |> Repo.one()
  end

  defp where_parent(query, nil), do: where(query, [c], is_nil(c.parent_id))
  defp where_parent(query, parent_id), do: where(query, [c], c.parent_id == ^parent_id)
end
