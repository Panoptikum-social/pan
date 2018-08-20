defmodule Pan.Updater.Filter do
  import Ecto.Query
  alias Pan.Repo
  alias PanWeb.Episode

  def only_new_items(feed_map, podcast_id) do
    existing_guids =
      from(e in Episode,
        where: e.podcast_id == ^podcast_id,
        select: e.guid
      )
      |> Repo.all()

    existing_titles =
      from(e in Episode,
        where: e.podcast_id == ^podcast_id,
        select: e.title
      )
      |> Repo.all()

    items =
      Quinn.find(feed_map, [:rss, :channel, :item])
      |> Enum.reject(&is_already_imported?(&1, :guid, existing_guids))
      |> Enum.reject(&is_already_imported?(&1, :title, existing_titles))
      |> Enum.reject(&is_already_imported?(&1, :subtitle, existing_titles))

    {:ok, items}
  end

  defp is_already_imported?(item, attribute, values) do
    case Enum.find(item[:value], &match?(%{name: ^attribute}, &1)) do
      nil ->
        false

      attribute_map ->
        Map.get(attribute_map, :value)
        |> List.first()
        |> (&Enum.member?(values, &1)).()
    end
  end
end
